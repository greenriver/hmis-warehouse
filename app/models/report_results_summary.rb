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

  # Not an access check: reaching a summary is gated by its report definition. This
  # only keeps summaries with at least one run the user may see.
  scope :runs_visible_to, -> (user) do
    if user.can_view_all_hud_reports?
      all
    else
      joins(:report_results).merge(ReportResult.runs_visible_to(user))
    end
  end
end
