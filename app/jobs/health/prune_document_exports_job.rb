module Health
  class PruneDocumentExportsJob < BaseJob
    queue_as :default

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
