###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Service for managing HUD report artifacts in S3 via ActiveStorage
# Handles storing report data as CSV files and JSON summaries
module HudReports
  class FileArtifactService
    include ActionView::Helpers::DateHelper

    def initialize(report_instance)
      @report = report_instance
    end

    # Store all report artifacts to S3
    def store_artifacts!
      # Prefer sharded universe members per question to reduce read size
      store_universe_members_csv_shards!
      store_report_clients_csv!
      store_cell_details_csv!
      store_report_summary_json!
    end

    # Store universe members as per-question shards
    def store_universe_members_csv_shards!
      # Avoid duplicating work if shards already exist
      return if @report.universe_members_csv_shards.attached? && @report.universe_members_csv_shards.attachments.any?

      questions = @report.report_cells.distinct.pluck(:question)
      questions.each do |question|
        csv_data = generate_universe_members_csv_for_question(question)
        filename = "universe_members_#{@report.class.table_name}_#{@report.id}_#{question}_#{Time.current.to_fs(:number)}.csv"

        @report.universe_members_csv_shards.attach(
          io: StringIO.new(csv_data),
          filename: filename,
          content_type: 'text/csv',
          metadata: { question: question },
        )
      end
    end

    # Store report clients as CSV
    def store_report_clients_csv!
      return if @report.report_clients_csv.attached?

      csv_data = generate_report_clients_csv
      filename = "report_clients_#{@report.id}_#{Time.current.to_fs(:number)}.csv"

      @report.report_clients_csv.attach(
        io: StringIO.new(csv_data),
        filename: filename,
        content_type: 'text/csv',
      )
    end

    # Store cell details as CSV
    def store_cell_details_csv!
      return if @report.cell_details_csv.attached?

      csv_data = generate_cell_details_csv
      filename = "cell_details_#{@report.id}_#{Time.current.to_fs(:number)}.csv"

      @report.cell_details_csv.attach(
        io: StringIO.new(csv_data),
        filename: filename,
        content_type: 'text/csv',
      )
    end

    # Store report summary as JSON
    def store_report_summary_json!
      return if @report.report_summary_json.attached?

      summary_data = generate_report_summary_json
      filename = "report_summary_#{@report.id}_#{Time.current.to_fs(:number)}.json"

      @report.report_summary_json.attach(
        io: StringIO.new(summary_data.to_json),
        filename: filename,
        content_type: 'application/json',
      )
    end

    # Retrieve universe members from S3 for a specific question shard
    # Returns a CSV::Table (headers: true) or nil if not available
    def retrieve_universe_members(question:)
      return nil if question.blank?
      return nil unless @report.universe_members_csv_shards.attached?

      attachment = @report.universe_members_csv_shards.attachments.find do |att|
        att.metadata&.fetch('question', nil) == question || att.filename.to_s.include?("_#{question}_")
      end

      return nil unless attachment

      blob = attachment.blob
      csv_content = Rails.cache.fetch(
        report_storage_cache_key(kind: 'universe_members_csv', blob: blob, question: question),
        expires_in: cache_expiry,
      ) do
        attachment.download
      end
      CSV.parse(csv_content, headers: true)
    end

    # Retrieve report clients from S3
    def retrieve_report_clients
      return nil unless @report.report_clients_csv.attached?

      blob = @report.report_clients_csv.blob
      csv_content = Rails.cache.fetch(report_storage_cache_key(kind: 'report_clients_csv', blob: blob), expires_in: cache_expiry) do
        @report.report_clients_csv.download
      end
      CSV.parse(csv_content, headers: true)
    end

    # Retrieve cell details from S3
    def retrieve_cell_details
      return nil unless @report.cell_details_csv.attached?

      blob = @report.cell_details_csv.blob
      csv_content = Rails.cache.fetch(report_storage_cache_key(kind: 'cell_details_csv', blob: blob), expires_in: cache_expiry) do
        @report.cell_details_csv.download
      end
      CSV.parse(csv_content, headers: true)
    end

    # Retrieve report summary from S3
    def retrieve_report_summary
      return nil unless @report.report_summary_json.attached?

      blob = @report.report_summary_json.blob
      json_content = Rails.cache.fetch(report_storage_cache_key(kind: 'report_summary_json', blob: blob), expires_in: cache_expiry) do
        @report.report_summary_json.download
      end
      JSON.parse(json_content)
    end

    # Check if artifacts are stored in S3 (delegate to model to avoid duplication)
    def artifacts_stored?
      @report.artifacts_stored?
    end

    # Clean up S3 artifacts (for testing or manual cleanup)
    def cleanup_artifacts!
      @report.report_clients_csv.purge if @report.report_clients_csv.attached?
      @report.cell_details_csv.purge if @report.cell_details_csv.attached?
      @report.report_summary_json.purge if @report.report_summary_json.attached?
    end

    private

    def report_storage_cache_key(kind:, blob:, question: nil)
      [self.class.name, 'report_storage', @report.class.name, @report.id, kind, question, blob&.key].compact
    end

    def cache_expiry
      Rails.env.development? ? 30.seconds : 12.hours
    end

    def generate_universe_members_csv_for_question(question)
      headers = ['report_cell_id', 'universe_membership_type', 'universe_membership_id', 'client_id', 'first_name', 'last_name']

      cell_ids = @report.report_cells.where(question: question).pluck(:id)

      CSV.generate(headers: headers, write_headers: true) do |csv|
        HudReports::UniverseMember.where(report_cell_id: cell_ids).find_each do |member|
          csv << [
            member.report_cell_id,
            member.universe_membership_type,
            member.universe_membership_id,
            member.client_id,
            member.first_name,
            member.last_name,
          ]
        end
      end
    end

    def generate_report_clients_csv
      classes = @report.associated_scope_classes
      return '' if classes.blank?

      # Collect headers
      excluded = ['id', 'created_at', 'updated_at', 'deleted_at']
      headers = classes.flat_map(&:column_names).uniq - excluded
      # Ensure common keys present even if they’re methods
      headers += ['id', 'client_id', 'project_id', 'data_source_id']
      headers.uniq!

      CSV.generate(headers: headers, write_headers: true) do |csv|
        classes.each do |klass|
          scope = if klass.column_names.include?('report_instance_id')
            klass.where(report_instance_id: @report.id)
          else
            # Handle different association patterns based on class name
            case klass.name
            when /^HudSpmReport::Fy\d{4}::Episode$/
              # Episode doesn't have report_instance_id, so we need to join through enrollments
              klass.joins(enrollments: :report_instance).
                where(hud_report_spm_enrollments: { report_instance_id: @report.id })
            when /^HudApr::Fy\d{4}::AprLivingSituation$/
              # AprLivingSituation belongs to AprClient, which has report_instance_id
              klass.joins(:apr_client).
                where(hud_report_apr_clients: { report_instance_id: @report.id })
            when /^HudApr::Fy\d{4}::CeAssessment$/
              # CeAssessment belongs to AprClient, which has report_instance_id
              klass.joins(:apr_client).
                where(hud_report_apr_clients: { report_instance_id: @report.id })
            when /^HudApr::Fy\d{4}::CeEvent$/
              # CeEvent belongs to AprClient, which has report_instance_id
              klass.joins(:apr_client).
                where(hud_report_apr_clients: { report_instance_id: @report.id })
            when /^HudDataQualityReport::Fy\d{4}::DqLivingSituation$/
              # DqLivingSituation belongs to DqClient, which has report_instance_id
              klass.joins(:dq_client).
                where(hud_report_dq_clients: { report_instance_id: @report.id })
            else
              # Default fallback - skip this class if we don't know how to handle it
              Rails.logger.warn "Unknown association pattern for #{klass.name} - skipping in report clients CSV"
              klass.none
            end
          end
          scope.find_each do |record|
            csv << headers.map { |h| record.respond_to?(h) ? record.public_send(h) : nil }
          end
        end
      end
    end

    def generate_cell_details_csv
      headers = ['report_instance_id', 'question', 'cell_name', 'universe', 'summary', 'status', 'any_members']

      CSV.generate(headers: headers, write_headers: true) do |csv|
        @report.report_cells.find_each do |cell|
          csv << [
            cell.report_instance_id,
            cell.question,
            cell.cell_name,
            cell.universe,
            cell.summary&.to_json,
            cell.status,
            cell.any_members,
          ]
        end
      end
    end

    def generate_report_summary_json
      {
        report_id: @report.id,
        report_name: @report.report_name,
        created_at: @report.created_at,
        completed_at: @report.completed_at,
        state: @report.state,
        question_names: @report.question_names,
        options: @report.options,
        cell_count: @report.report_cells.count,
        universe_member_count: @report.report_cells.joins(:universe_members).count,
        storage_timestamp: Time.current,
      }
    end
  end
end
