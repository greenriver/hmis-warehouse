###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AcHmis
  class ReportsController < Hmis::BaseController
    def prevention_assessment_report
      report = AcHmis::ReportApi.new.prevention_assessment_report(referral_id: params[:referral_id])

      render body: report.body, status: report.http_status, content_type: 'application/pdf'
    end
  end
end
