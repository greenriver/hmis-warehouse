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

    def mper_id(record)
      mper_cred.external_ids.where(source: record).first!.value
    end

    def mper_cred
      @mper_cred ||= ::HmisExternalApis::AcHmis::MperCredential.first!
    end

    def mci_cred
      @mci_cred ||= ::HmisExternalApis::AcHmis::MciCredential.first!
    end
  end
end
