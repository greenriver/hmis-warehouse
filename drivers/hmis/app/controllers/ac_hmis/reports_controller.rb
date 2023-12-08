###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AcHmis
  class ReportsController < Hmis::BaseController
    def prevention_assessment_report
      referral_id = params[:referral_id]
      referral = HmisExternalApis::AcHmis::Referral.find_by(identifier: referral_id)
      raise HmisErrors::ApiError, "Referral not found (ID: #{referral_id})" unless referral.present?

      # Find the project that this referral is for, and ensure that user has permission to view postings at it
      project_referred_to = referral.postings&.first&.project
      raise HmisErrors::ApiError, "Project not found for referral (ID: #{referral_id})" unless project_referred_to
      raise HmisErrors::ApiError, 'Access denied' unless current_hmis_user.can_manage_incoming_referrals_for?(project_referred_to)

      report = AcHmis::ReportApi.new.prevention_assessment_report(referral_id: referral_id)

      render body: report.body, status: report.http_status, content_type: 'application/pdf'
    end
  end
end
