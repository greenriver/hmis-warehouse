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

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def system_user
      @system_user ||= ::Hmis::Hud::User.system_user(data_source_id: data_source.id)
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

    # @param date [Time, DateTime]
    def format_datetime(value)
      case value
      when Time, DateTime
        value.in_time_zone(Rails.configuration.time_zone).iso8601
      else
        value&.iso8601
      end
    end

    # @param str [String]
    def format_requested_by(str)
      str.slice(0, 50) # max length of 50 for requestedBy
    end
  end
end
