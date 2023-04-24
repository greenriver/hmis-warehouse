###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ReferralsController < BaseController
    before_action :authorize_request
    skip_before_action :authenticate_user!
    prepend_before_action :skip_timeout

    def create
      referral = HmisExternalApis::CreateReferralJob.perform_now(params: unsafe_params)
      render json: { message: 'Referral Created', id: referral.identifier }
    end

    protected

    def unsafe_params
      @unsafe_params ||= params.permit!.to_h
    end

    def authorize_request
      # FIXME: token auth or oauth?
      raise unless Rails.env.development? || Rails.env.test?
    end
  end
end
