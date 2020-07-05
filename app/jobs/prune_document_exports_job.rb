class PruneDocumentExportsJob < ApplicationJob
  queue_as :default

  def perform
    DocumentExport.with_advisory_lock(
      'prune_document_exports_job',
      timeout_seconds: 0,
    ) do
      DocumentExport.expired.destroy_all
    end
  end
end
