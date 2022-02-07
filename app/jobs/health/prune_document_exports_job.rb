###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PruneDocumentExportsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform
      Health::DocumentExport.with_advisory_lock(
        'health_prune_document_exports_job',
        timeout_seconds: 0,
      ) do
        Health::DocumentExport.expired.diet_select.destroy_all
      end
    end
  end
end
