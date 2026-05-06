###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPathReport
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :path_clients_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def shared_archival_entries(report_instance)
        {
          universe_members_csv: {
            scope: -> { ::HudReports::UniverseMember.where(report_cell_id: report_instance.report_cells.select(:id)) },
            filename: -> { "hud-path-#{report_instance.id}-universe-members.csv" },
            delete_order: 1,
          },
          report_cells_csv: {
            scope: -> { report_instance.report_cells },
            filename: -> { "hud-path-#{report_instance.id}-cells.csv" },
            delete_order: 99,
          },
        }
      end

      def archival_csv_config(report_instance)
        shared_archival_entries(report_instance).merge(
          path_clients_csv: {
            scope: -> { HudPathReport::Fy2020::PathClient.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-path-#{report_instance.id}-clients.csv" },
            delete_order: 2,
          },
        )
      end
    end
  end
end
