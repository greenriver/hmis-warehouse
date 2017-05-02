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