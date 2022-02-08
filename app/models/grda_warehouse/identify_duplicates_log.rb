###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::IdentifyDuplicatesLog < GrdaWarehouseBase
  self.table_name = 'identify_duplicates_log'
  include ActionView::Helpers::DateHelper

  def import_time
    if completed_at.present?
      seconds = ((completed_at - started_at)/1.minute).round * 60
      distance_of_time_in_words(seconds)
    else
      'incomplete'
    end
  end

end
