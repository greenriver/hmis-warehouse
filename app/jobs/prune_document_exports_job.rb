###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class PruneDocumentExportsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform
    GrdaWarehouse::DocumentExport.with_advisory_lock(
      'prune_document_exports_job',
      timeout_seconds: 0,
    ) do
      instrument_as_maintenance_task(name: 'prune expired exports') do |run|
        GrdaWarehouse::DocumentExport.expired.diet_select.find_each(&:destroy!)
        run.complete!
      end
    end
  end
end
