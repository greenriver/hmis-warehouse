###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPit
  module Archival
    extend ActiveSupport::Concern

    included do
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
