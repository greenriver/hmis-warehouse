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

    def consumer_summary_report
      client = Hmis::Hud::Client.find_by(id: params[:client_id])
      umci = client&.ac_hmis_mci_unique_id&.value
      return render body: "No UMCI found for client with ID '#{params[:client_id]}'", status: 404 unless umci.present?

      report = AcHmis::ReportApi.new.consumer_summary_report(umci: umci, **params.slice(:start_date, :end_date))

      render body: report.body, status: report.http_status, content_type: 'application/pdf'
    end
  end
end
