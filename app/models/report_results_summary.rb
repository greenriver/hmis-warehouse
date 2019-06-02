###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ReportResultsSummary < ActiveRecord::Base
  require 'csv'
  include ActionView::Helpers::DateHelper
  has_many :reports
  has_many :report_results, through: :reports

  # override in sub-class for alternate downloads
  def report_download_format
    nil
  end
end