###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportResultsSummary < ApplicationRecord
  require 'csv'
  include ActionView::Helpers::DateHelper
  has_many :reports
  has_many :report_results, through: :reports
  has_many :users, through: :report_results

  # override in sub-class for alternate downloads
  def report_download_format
    nil
  end

  scope :viewable_by, -> (user) do
    if user.can_view_all_hud_reports?
      all
    elsif user.can_view_own_hud_reports?
      joins(:report_results).merge(ReportResult.viewable_by(user))
    else
      none
    end
  end
end
