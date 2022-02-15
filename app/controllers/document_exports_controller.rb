###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
