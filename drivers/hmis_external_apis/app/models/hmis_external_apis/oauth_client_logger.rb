###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class OauthClientLogger
    def capture(creds:, url:, method:, payload:, headers:)
      record = new_log_record(
        initiator: creds,
        url: url,
        http_method: method,
        request: payload || {},
        request_headers: headers,
        requested_at: Time.current,
        response: 'pending', # can't be null
      )

      result = nil
      begin
        result = yield
      rescue StandardError => e
        update_log_record(record, { response: e.message || 'error' })
        raise
      end
      update_log_record(record, { content_type: result.content_type, response: result.body, http_status: result.status }) if result
      [result, record]
    end

    protected

    def new_log_record(...)
      HmisExternalApis::ExternalRequestLog.create!(...)
    end

    def update_log_record(record, attrs)
      # Capture logging to stdout too, because ExternalRequestLog is sometimes being rolled back in transactions
      Rails.logger.info "ExternalRequestLog captured: URL:#{record.url}, REQUEST:#{record.payload}, RESPONSE:#{attrs}"
      record.update!(attrs)
    end
  end
end
