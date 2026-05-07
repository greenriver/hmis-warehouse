###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPit
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReports::ReportInstance.class_eval do
        has_one_attached :pit_clients_csv
      end

      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def archival_csv_config(report_instance)
        HudReportArchival.shared_archival_entries(report_instance, prefix: 'pit').merge(
          pit_clients_csv: {
            scope: -> { HudPit::Fy2022::PitClient.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-pit-#{report_instance.id}-clients.csv" },
            delete_order: 2,
          },
        )
      end
    end
  end
end
