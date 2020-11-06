###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportsController < DocumentExportsControllerBase
  private def document_export_class
    GrdaWarehouse::DocumentExport
  end

  private def export_job_class
    DocumentExportJob
  end

  private def export_scope
    current_user.document_exports
  end

  private def generate_document_export_path(id)
    document_export_path(id)
  end

  private def generate_download_document_export_path(id)
    download_document_export_path(id)
  end
end
if Rails.env.development?
  # require subclasses are populated for validation of acceptable types
  require_dependency 'grda_warehouse/document_exports/client_performance_export'
  require_dependency 'grda_warehouse/document_exports/household_performance_export'
  require_dependency 'grda_warehouse/document_exports/project_type_performance_export'
end
