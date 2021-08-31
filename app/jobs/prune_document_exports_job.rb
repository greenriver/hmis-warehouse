###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PruneDocumentExportsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform
    GrdaWarehouse::DocumentExport.with_advisory_lock(
      'prune_document_exports_job',
      timeout_seconds: 0,
    ) do
      GrdaWarehouse::DocumentExport.expired.diet_select.destroy_all
    end
  end
end
