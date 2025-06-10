# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PruneDocumentExportsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform
    instrument_as_maintenance_task(name: 'perform') do |run|
      GrdaWarehouse::DocumentExport.with_advisory_lock(
        'prune_document_exports_job',
        timeout_seconds: 0,
      ) do
        GrdaWarehouse::DocumentExport.expired.diet_select.find_each(&:destroy!)
        run.complete!
      end
    end
  end
end
