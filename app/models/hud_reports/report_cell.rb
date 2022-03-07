###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A HUD report cell, identified by a question and cell name (e.g., question: 'Q1', cell_name: 'b2')
module HudReports
  class ReportCell < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    self.table_name = 'hud_report_cells'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    has_many :universe_members # , dependent: :destroy # for the moment this is too slow

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
      @members ||= join_universe
    end

    def count
      @count ||= universe_members.count
    end

    def add_members(members)
      UniverseMember.import(
        members.map { |member| copy_member(member) },
        validate: false,
        on_duplicate_key_ignore: true,
      )
    end

    # Add members to the universe of this cell
    #
    # @param members [Hash<Client, ReportClientBase] the members to be associated with this cell
    def add_universe_members(members)
      UniverseMember.import(
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

    private def new_member(warehouse_client:, universe_client:)
      if universe_client.respond_to?(:first_name)
        UniverseMember.new(
          report_cell: self,
          client_id: warehouse_client.id,
          first_name: universe_client.first_name,
          last_name: universe_client.last_name,
          universe_membership: universe_client,
        )
      else
        UniverseMember.new(
          report_cell: self,
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
      universe_table_name = universe_members.first.universe_membership.class.arel_table
      members_table = universe_members.arel_table

      table_join = members_table.join(universe_table_name).on(members_table[:universe_membership_id].eq(universe_table_name[:id]))
      universe_members.joins(table_join.join_sources)
    end
  end
end
