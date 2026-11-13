###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  class CellDetailExportJob < ::BaseJob
    include DocumentExportJobBehavior

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    private

    def export_scope
      HudSpmReport::DocumentExports::CellDetailExport
    end
  end
end
