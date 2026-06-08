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
      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def archival_csv_config(report_instance)
        HudReportArchival.shared_archival_entries(report_instance, prefix: 'path').merge(
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
