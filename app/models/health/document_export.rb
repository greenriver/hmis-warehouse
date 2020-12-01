###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Health::DocumentExport < HealthBase
  include DocumentExportBehavior

  def data_url
    health_document_exports_path
  end

  def download_url
    download_health_document_export_url(id, host: ENV['FQDN'])
  end

end
