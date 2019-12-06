###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::ImportLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
  serialize :files
  serialize :import_errors
  serialize :summary
  belongs_to :data_source
  belongs_to :upload, required: false

  scope :viewable_by, -> (user) do
    where(data_source_id: GrdaWarehouse::DataSource.viewable_by(user).select(:id))
  end

  def import_time(details: false)
    if completed_at.present?
      seconds = ((completed_at - created_at)/1.minute).round * 60
      distance_of_time_in_words(seconds)
    elsif upload.present?
      upload.import_time(details: details)
    else
      if updated_at < 2.days.ago
        'failed'
      else
        'processing...'
      end
    end
  end
end