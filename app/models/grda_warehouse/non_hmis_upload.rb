module GrdaWarehouse
  class NonHmisUpload < GrdaWarehouseBase

    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name
    belongs_to :user, required: true

    belongs_to :delayed_job, required: false, class_name: Delayed::Job.name

    mount_uploader :file, ImportUploader
    validates :data_source, presence: true
    validates :file, presence: true, on: :create

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

    def import_time(details: false)
      if delayed_job.present?
        if delayed_job.last_error.present? && details
          return "Failed with: #{delayed_job.last_error.split("\n").first}"
        elsif delayed_job.failed_at.present? || delayed_job.last_error.present?
          return  'failed'
        end
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