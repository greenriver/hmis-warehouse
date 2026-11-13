###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReportArchival.register_archival_generator(title, self)
    end

    module ClassMethods
      def archival_csv_config(report_instance)
        client_ids = HudDataQualityReport::Fy2020::DqClient.where(report_instance_id: report_instance.id).select(:id)

        HudReportArchival.shared_archival_entries(report_instance, prefix: 'dq').merge(
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
