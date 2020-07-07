class PruneDocumentExportsJob < ApplicationJob
  queue_as :default

  def perform
    DocumentExport.with_advisory_lock(
      'prune_document_exports_job',
      timeout_seconds: 0,
    ) do
      DocumentExport.expired.diet_select.destroy_all
    end
  end
end
