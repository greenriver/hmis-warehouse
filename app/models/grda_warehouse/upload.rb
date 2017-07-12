module GrdaWarehouse
  class Upload < GrdaWarehouseBase
    require 'csv'
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name
    belongs_to :user, required: true
    has_one :import_log, -> { where.not(completed_at: nil)}, primary_key: [:data_source_id, :completed_at], foreign_key: [:data_source_id, :completed_at]

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

    def import_time
      if percent_complete == 100
        seconds = ((completed_at - created_at)/1.minute).round * 60
        distance_of_time_in_words(seconds)
      else
        'incomplete'
      end
    end

  end
end