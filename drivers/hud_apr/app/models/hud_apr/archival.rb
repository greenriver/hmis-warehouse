###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :apr_clients_csv
        has_one_attached :apr_living_situations_csv
        has_one_attached :apr_ce_assessments_csv
        has_one_attached :apr_ce_events_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def shared_archival_entries(report_instance)
        {
          universe_members_csv: {
            scope: -> { ::HudReports::UniverseMember.where(report_cell_id: report_instance.report_cells.select(:id)) },
            filename: -> { "hud-apr-#{report_instance.id}-universe-members.csv" },
            delete_order: 1,
          },
          report_cells_csv: {
            scope: -> { report_instance.report_cells },
            filename: -> { "hud-apr-#{report_instance.id}-cells.csv" },
            delete_order: 99,
          },
        }
      end

      def archival_csv_config(report_instance)
        client_ids = HudApr::Fy2020::AprClient.where(report_instance_id: report_instance.id).select(:id)

        shared_archival_entries(report_instance).merge(
          apr_living_situations_csv: {
            scope: -> { HudApr::Fy2020::AprLivingSituation.where(hud_report_apr_client_id: client_ids) },
            filename: -> { "hud-apr-#{report_instance.id}-living-situations.csv" },
            delete_order: 2,
          },
          apr_ce_assessments_csv: {
            scope: -> { HudApr::Fy2020::CeAssessment.where(hud_report_apr_client_id: client_ids) },
            filename: -> { "hud-apr-#{report_instance.id}-ce-assessments.csv" },
            delete_order: 3,
          },
          apr_ce_events_csv: {
            scope: -> { HudApr::Fy2020::CeEvent.where(hud_report_apr_client_id: client_ids) },
            filename: -> { "hud-apr-#{report_instance.id}-ce-events.csv" },
            delete_order: 4,
          },
          apr_clients_csv: {
            scope: -> { HudApr::Fy2020::AprClient.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-apr-#{report_instance.id}-clients.csv" },
            delete_order: 5,
          },
        )
      end
    end
  end
end
