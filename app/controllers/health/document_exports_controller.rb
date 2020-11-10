###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class DocumentExportsController < DocumentExportsControllerBase
    private def document_export_class
      Health::DocumentExport
    end

    private def export_job_class
      Health::DocumentExportJob
    end

    private def export_scope
      current_user.health_document_exports
    end

    private def generate_document_export_path(id)
      health_document_export_path(id)
    end

    private def generate_download_document_export_path(id)
      download_health_document_export_path(id)
    end
  end
end
if Rails.env.development?
  # require subclasses are populated for validation of acceptable types
  require_dependency 'health/document_exports/housing_status_changes_export'
  require_dependency 'health/document_exports/agency_performance_export'
end
