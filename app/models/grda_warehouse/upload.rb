###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Upload < GrdaWarehouseBase
    require 'csv'
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :user, optional: true

    belongs_to :delayed_job, optional: true, class_name: '::Delayed::Job'
    has_one :import_log, class_name: 'GrdaWarehouse::ImportLog', required: false

    mount_uploader :file, ImportUploader
    validates :data_source, presence: true
    validates :file, presence: true, on: :create

    scope :completed, -> do
      where(percent_complete: 100)
    end

    scope :viewable_by, ->(user) do
      where(data_source_id: GrdaWarehouse::DataSource.directly_viewable_by(user).select(:id))
    end

    def has_import_log? # rubocop:disable Naming/PredicateName
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
          distance_of_time_in_words(seconds)
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
    # Overrides some methods, so must be included at the end
    include RailsDrivers::Extensions
  end
end
