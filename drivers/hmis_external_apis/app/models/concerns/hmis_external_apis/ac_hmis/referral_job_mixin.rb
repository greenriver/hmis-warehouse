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
      @mci ||= ::HmisExternalApis::AcHmis::Mci.new
    end

    def mper
      @mper ||= ::HmisExternalApis::AcHmis::Mper.new
    end

    def link
      @link ||= ::HmisExternalApis::AcHmis::LinkApi.new
    end

    # @param date [Time, DateTime]
    def format_date(value)
      date = case value
      when Time, DateTime
        value.in_time_zone(Rails.configuration.time_zone).to_date
      else
        value
      end
      date&.strftime('%Y-%m-%d')
    end

    # @param str [String]
    def format_requested_by(str)
      str.slice(0, 20) # max length of 20 for requestedBy
    end
  end
end
