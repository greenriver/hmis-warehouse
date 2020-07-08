class PruneDocumentExportsJob < BaseJob
  queue_as :default

  def perform
    GrdaWarehouse::DocumentExport.with_advisory_lock(
      'prune_document_exports_job',
      timeout_seconds: 0,
    ) do
      GrdaWarehouse::DocumentExport.expired.diet_select.destroy_all
    end
  end
end
