###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A HUD report cell, identified by a question and cell name (e.g., question: 'Q1', cell_name: 'b2')
# * the cell value appears to be stored in the "summary" field
# * sometimes a cell is a question group (q6) with sub-questions (6a, 6b, etc.,)
# * cells may also persist application errors in cell.error_messages
module HudReports
  class ReportCell < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    self.table_name = 'hud_report_cells'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    has_many :universe_members # , dependent: :destroy # for the moment this is too slow

    alias_attribute :value, :summary

    # summary is a json col for some reason
    def numeric_value
      case summary
      when Integer, Float
        summary
      when /\A[-+]?[0-9]+\z/
        summary.to_i
      when /\A[-+]?[0-9]*\.?[0-9]+\z/
        summary.to_f
      end
    end

    scope :universe, -> do
      where(universe: true)
    end

    scope :for_question, ->(question) do
      where(question: question)
    end

    scope :for_table, ->(table) do
      where(question: table)
    end

    scope :for_cell, ->(cell) do
      where(cell_name: cell)
    end

    def user
      report_instance.user
    end

    def members
      @members ||= if report_instance.artifacts_stored?
        load_members_from_s3
      else
        join_universe
      end
    end

    def count
      @count ||= if report_instance.artifacts_stored?
        count_from_s3
      else
        universe_members.count
      end
    end

    def add_members(members)
      UniverseMember.import(
        members.map { |member| copy_member(member) },
        validate: false,
        on_duplicate_key_ignore: true,
      )
      # If we just added members, make note that we have some so we can display
      # the link correctly in the UI. Don't save, that's done in the calling report
      self.any_members = true if members.count.positive?
    end

    # Add members to the universe of this cell
    #
    # @param members [Hash<Client, ReportClientBase] the members to be associated with this cell
    def add_universe_members(members)
      UniverseMember.import!(
        members.map { |client, universe_client| new_member(warehouse_client: client, universe_client: universe_client) },
        validate: false,
        on_duplicate_key_ignore: true,
      )
    end

    def completed_in
      return nil unless completed?

      seconds = ((updated_at - created_at) / 1.minute).round * 60
      distance_of_time_in_words(seconds)
    end

    def completed?
      status == 'Completed'
    end

    # Render XLSX download to string, and save to path
    def write_detail(path:, generator:, question_name:)
      return unless path.present?

      q = generator.valid_question_number(question_name)
      name = "#{generator.file_prefix} #{q} #{cell_name}"
      headers = generator.column_headings(q)
      clients = generator.client_class(q).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(question).for_cell(cell_name)).
        merge(::HudReports::ReportInstance.where(id: report_instance.id))

      template = generator.detail_template
      xlsx_data = ApplicationController.render(
        template: template,
        formats: [:xlsx],
        assigns: {
          report: report_instance,
          question: q,
          table: question,
          cell: cell_name,
          name: name,
          headers: headers,
          clients: clients,
        },
      )
      cell_path = "#{path}#{question}-#{cell_name}.xlsx"
      File.binwrite(cell_path, xlsx_data)
    end

    # NOTE: sometimes warehouse_client isn't a client at all, but potentially an inventory record
    private def new_member(warehouse_client:, universe_client:)
      if universe_client.respond_to?(:first_name)
        UniverseMember.new(
          report_cell: self,
          client_id: warehouse_client&.id,
          first_name: universe_client.first_name,
          last_name: universe_client.last_name,
          universe_membership: universe_client,
        )
      elsif warehouse_client.respond_to?(:first_name)
        UniverseMember.new(
          report_cell: self,
          client_id: warehouse_client.id,
          first_name: warehouse_client.first_name,
          last_name: warehouse_client.last_name,
          universe_membership: universe_client,
        )
      else
        UniverseMember.new(
          report_cell: self,
          client_id: warehouse_client.id,
          universe_membership: universe_client,
        )
      end
    end

    private def copy_member(member)
      if member.respond_to?(:first_name)
        UniverseMember.new(
          report_cell: self,
          client_id: member.client_id,
          first_name: member.first_name,
          last_name: member.last_name,
          universe_membership_type: member.universe_membership_type,
          universe_membership_id: member.universe_membership_id,
        )
      else
        UniverseMember.new(
          report_cell: self,
          universe_membership_type: member.universe_membership_type,
          universe_membership_id: member.universe_membership_id,
        )
      end
    end

    private def join_universe
      return self.class.none if count.zero?

      # joins don't work for polymorphic associations since it could join multiple tables.
      # However, for a given report cell, all of the universe members must be in the same table
      # and we can compute the name based on a single member.
      # NOTE: need to specify order by report_cell_id or the postgres planner gets really unhappy when
      # the universe members table gets large
      universe_table_name = universe_members.order(:report_cell_id).first.universe_membership.class.arel_table
      members_table = universe_members.arel_table

      table_join = members_table.join(universe_table_name).on(members_table[:universe_membership_id].eq(universe_table_name[:id]))
      universe_members.joins(table_join.join_sources)
    end

    def load_members_from_s3
      service = HudReports::S3ArtifactService.new(report_instance)
      csv_data = service.retrieve_universe_members(question: question)

      return self.class.none unless csv_data

      # Filter universe members for this specific cell
      cell_members = csv_data.select { |row| row['report_cell_id'].to_i == id }

      Rails.logger.info "Loaded #{cell_members.count} members from S3 for cell #{id} (report #{report_instance.id})"

      # Convert to a format that mimics the original universe members
      cell_members.map do |row|
        OpenStruct.new(
          report_cell_id: row['report_cell_id'].to_i,
          universe_membership_type: row['universe_membership_type'],
          universe_membership_id: row['universe_membership_id'].to_i,
          client_id: row['client_id'].to_i,
          first_name: row['first_name'],
          last_name: row['last_name'],
        )
      end
    end

    def count_from_s3
      service = HudReports::S3ArtifactService.new(report_instance)
      csv_data = service.retrieve_universe_members(question: question)

      return 0 unless csv_data

      # Count universe members for this specific cell
      count = csv_data.count { |row| row['report_cell_id'].to_i == id }
      Rails.logger.info "Counted #{count} members from S3 for cell #{id} (report #{report_instance.id})"
      count
    end
  end
end
