###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  module Archival
    extend ActiveSupport::Concern

    included do
      # Declare all SPM-specific attachments on ReportInstance (union across all fiscal years).
      # Repeated class_eval calls for the same attachment name are idempotent in Rails.
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :spm_clients_csv
        has_one_attached :spm_enrollments_csv
        has_one_attached :spm_enrollment_links_csv
        has_one_attached :spm_episodes_csv
        has_one_attached :spm_returns_csv
        has_one_attached :spm_bed_nights_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end
  end
end
