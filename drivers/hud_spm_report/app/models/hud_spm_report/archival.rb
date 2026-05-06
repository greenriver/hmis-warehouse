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

    module ClassMethods
      def shared_archival_entries(report_instance)
        {
          universe_members_csv: {
            scope: -> { ::HudReports::UniverseMember.where(report_cell_id: report_instance.report_cells.select(:id)) },
            filename: -> { "hud-spm-#{report_instance.id}-universe-members.csv" },
            delete_order: 1,
          },
          report_cells_csv: {
            scope: -> { report_instance.report_cells },
            filename: -> { "hud-spm-#{report_instance.id}-cells.csv" },
            delete_order: 99,
          },
        }
      end

      def archival_csv_config(_report_instance)
        raise NotImplementedError, "#{name} must implement self.archival_csv_config"
      end
    end
  end
end
