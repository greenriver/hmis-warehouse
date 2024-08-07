###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The export is generated elsewhere. This just orchestrates running the job and
# returning the result.

module HmisExternalApis::AcHmis::Exporters
  class HmisExportFetcher
    include Rails.application.routes.url_helpers

    attr_accessor :export

    delegate :content, to: :export

    def run!(start_date: 3.years.ago.to_date)
      data_source = HmisExternalApis::AcHmis.data_source
      user = User.system_user
      version = '2024'

      filter = ::Filters::HmisExport.new(
        data_source_ids: [data_source.id],
        version: version,
        user_id: user.id,
        start_date: start_date,
      )

      Rails.logger.info 'Generating HMIS CSV Export'

      job_info = filter.execute_job(report_url: warehouse_reports_hmis_exports_url)

      export_id = job_info.arguments[3][:args][1]

      self.export = ::GrdaWarehouse::HmisExport.find(export_id)
    end
  end
end
