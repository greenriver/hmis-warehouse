module GrdaWarehouse
  class Upload < GrdaWarehouseBase
    require 'csv'
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name
    belongs_to :user, required: true

    belongs_to :delayed_job, required: false, class_name: Delayed::Job.name
    has_one :import_log, class_name: GrdaWarehouse::ImportLog.name, required: false

    mount_uploader :file, ImportUploader
    validates :data_source, presence: true
    validates :file, presence: true, on: :create

    def has_import_log?
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
      if percent_complete == 0
        'Queued'
      elsif percent_complete == 0.01
        'Started'
      elsif percent_complete == 100
        'Complete'
      else
        percent_complete
      end
    end

    def import_time
      if delayed_job_id.present? && delayed_job.failed_at.present?
        return 'failed'
      end
      if percent_complete == 100
        begin
          seconds = ((completed_at - created_at)/1.minute).round * 60
          distance_of_time_in_words(seconds)
        rescue
          'unknown'
        end
      else
        'incomplete'
      end
    end

  end
end