###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  def report_definition_url
    Report.hud_definition_url_for(type)
  end

  scope :viewable_by, -> (user) do
    if user.can_view_all_hud_reports?
      all
    else
      joins(:report_results).merge(ReportResult.viewable_by(user))
    end
  end
end
