###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# common behavior for referral processing
module HmisExternalApis::AcHmis
  module ReferralJobMixin
    extend ActiveSupport::Concern

    protected

    # post params to external api
    def post_referral_request(url, params)
      # FIXME: add authentication
      response = Faraday.post(url, params)
      JSON.parse(response.body)
    end

    def mci
      @mci ||= ::HmisExternalApis::Mci.new
    end

    def mper
      @mper ||= ::HmisExternalApis::AcHmis::Mper.new
    end
  end
end
