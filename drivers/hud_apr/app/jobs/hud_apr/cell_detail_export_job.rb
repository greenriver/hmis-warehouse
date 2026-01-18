###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class CellDetailExportJob < ::BaseJob
    include DocumentExportJobBehavior

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    private

    def export_scope
      HudApr::DocumentExports::CellDetailExport
    end
  end
end
