module Health
  class DocumentExportJob < BaseJob
    queue_as :default

    def perform(export_id: nil)
      export = load_export(export_id)
      if export
        export.perform
      else
        Rails.logger.warn("[#{self.class.name}] skipping export id #{export_id}")
      end
    end

    protected

    def load_export(id)
      Health::DocumentExport.
        not_expired.
        with_current_version.
        where(id: id).
        first
    end
  end
end
