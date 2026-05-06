###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :dq_clients_csv
        has_one_attached :dq_living_situations_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def shared_archival_entries(report_instance)
        {
          universe_members_csv: {
            scope: -> { ::HudReports::UniverseMember.where(report_cell_id: report_instance.report_cells.select(:id)) },
            filename: -> { "hud-dq-#{report_instance.id}-universe-members.csv" },
            delete_order: 1,
          },
          report_cells_csv: {
            scope: -> { report_instance.report_cells },
            filename: -> { "hud-dq-#{report_instance.id}-cells.csv" },
            delete_order: 99,
          },
        }
      end

      def archival_csv_config(report_instance)
        client_ids = HudDataQualityReport::Fy2020::DqClient.where(report_instance_id: report_instance.id).select(:id)

        shared_archival_entries(report_instance).merge(
          dq_living_situations_csv: {
            scope: -> { HudDataQualityReport::Fy2020::DqLivingSituation.where(hud_report_dq_client_id: client_ids) },
            filename: -> { "hud-dq-#{report_instance.id}-living-situations.csv" },
            delete_order: 2,
          },
          dq_clients_csv: {
            scope: -> { HudDataQualityReport::Fy2020::DqClient.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-dq-#{report_instance.id}-clients.csv" },
            delete_order: 3,
          },
        )
      end
    end
  end
end
