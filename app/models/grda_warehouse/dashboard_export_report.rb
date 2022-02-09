###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::DashboardExportReport < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
  belongs_to :file, class_name: 'GrdaWarehouse::DashboardExportFile', optional: true

  def complete?
    completed_at.present?
  end

  def completed_in
    return '' unless complete?

    seconds = ((completed_at - created_at) / 1.minute).round * 60
    distance_of_time_in_words(seconds)
  end

  def user_name
    if user_id.present?
      User.find(user_id).name
    else
      ''
    end
  end

  def display_coc_code
    if coc_code.present?
      coc_code
    else
      'All'
    end
  end

  def status
    if complete?
      "Completed in #{completed_in}"
    elsif started_at.present?
      'Started'
    else
      'Queued'
    end
  end
end
