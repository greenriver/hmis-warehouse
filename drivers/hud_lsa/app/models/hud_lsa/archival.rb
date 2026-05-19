###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudLsa
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :lsa_summary_results_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end
  end
end
