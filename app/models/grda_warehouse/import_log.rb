class GrdaWarehouse::ImportLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
  serialize :files, Hash
  serialize :import_errors, Hash
  serialize :summary, Hash
  belongs_to :data_source

  def import_time
    if completed_at.present?
      seconds = ((completed_at - created_at)/1.minute).round * 60
      distance_of_time_in_words(seconds)
    else
      'incomplete'
    end
  end
end