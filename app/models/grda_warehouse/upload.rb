###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class Upload < GrdaWarehouseBase
    require 'csv'
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    # Used for uploaded files, not stored on the upload, but passed to the job to indicate
    # if the import should be paused before overwriting the existing warehouse data
    attr_accessor :dry_run

    # Typed by the user to confirm the upload destination; checked by
    # UploadsController#create and not persisted
    attr_accessor :short_name_confirmation

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :user, optional: true

    belongs_to :delayed_job, optional: true, class_name: '::Delayed::Job'
    has_one :import_log, class_name: 'GrdaWarehouse::ImportLog', required: false

    has_one_attached :hmis_zip
    validates :data_source, presence: true
    validates :hmis_zip, presence: true, on: :create

    scope :completed, -> do
      where(percent_complete: 100)
    end

    scope :viewable_by, ->(user) do
      where(data_source_id: GrdaWarehouse::DataSource.directly_viewable_by(user, permission: :can_upload_hud_zips).select(:id))
    end

    def has_import_log? # rubocop:disable Naming/PredicatePrefix
      @has_import_log ||= GrdaWarehouse::ImportLog.where.not(completed_at: nil).
        where(data_source_id: data_source_id, completed_at: completed_at).
        exists?
    end

    def import_log_id
      return nil unless has_import_log?

      GrdaWarehouse::ImportLog.where.not(completed_at: nil).
        where(data_source_id: data_source_id, completed_at: completed_at).pluck(:id).first
    end

    def status
      if percent_complete.zero?
        'Queued'
      elsif percent_complete == 0.01
        'Started'
      elsif percent_complete == 100
        'Complete'
      else
        percent_complete
      end
    end

    def import_time(details: false)
      if delayed_job.present?
        return "Failed with: #{delayed_job.last_error.split("\n").first}" if delayed_job.last_error.present? && details
        return 'failed' if delayed_job.failed_at.present? || delayed_job.last_error.present?
      end
      if percent_complete == 100
        begin
          seconds = ((completed_at - created_at) / 1.minute).round * 60
          "#{distance_of_time_in_words(seconds)} -#{created_at.strftime('%l:%M %P')} to #{completed_at.strftime('%l:%M %P')}"
        rescue Exception
          'unknown'
        end
      else
        if updated_at < 2.days.ago # rubocop:disable Style/IfInsideElse
          'failed'
        else
          'processing...'
        end
      end
    end

    # Written by UploadsController#confirm when a user acknowledged a SourceID
    # HmisCsvImporter::ExportSourceCheck could not match against the data source.
    # Keys: typed_short_name, data_source_source_id, file_source_id,
    # file_source_name, check_error, acknowledged_at, acknowledged_by_user_id.
    def export_source_acknowledged?
      export_source_check.present? && export_source_check['acknowledged_at'].present?
    end

    # The acknowledgment let an unmatched SourceID through, so the Loader's own
    # comparison was skipped for this import.
    def source_id_overridden?
      return false unless export_source_acknowledged?

      expected = export_source_check['data_source_source_id']
      return false if expected.blank?

      observed = export_source_check['file_source_id']
      if observed.blank?
        # No SourceID was read here, either because Export.csv carried none or
        # because the archive could not be opened. Only the first needs an
        # override; in the second the Loader can still read the file itself
        # once the import has expanded it, so leave its comparison in place.
        return export_source_check['check_error'].blank?
      end

      !expected.casecmp(observed).zero?
    end

    # Created but never enqueued: the user abandoned the confirmation step.
    def awaiting_confirmation?
      delayed_job_id.nil? && !export_source_acknowledged? && percent_complete.to_f.zero?
    end

    def export_source_expected_id
      export_source_check&.dig('data_source_source_id')
    end

    def export_source_file_id
      export_source_check&.dig('file_source_id')
    end

    # Overrides some methods, so must be included at the end
    # Extensions from drivers — see ADR 0007
    include HmisCsvImporter::GrdaWarehouse::UploadExtension
    include HmisCsvTwentyTwenty::GrdaWarehouse::UploadExtension
  end
end
