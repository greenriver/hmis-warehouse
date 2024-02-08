###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
        # If an exception occurred, it was on or and or a failure to connect. Storing "400" status code to indicate it was on our side (the client)
        update_log_record(record, { response: "#{e.class.name}: #{e.message || 'Unknown error'}", http_status: 400 })
        raise
      end

      if result
        attrs = {
          content_type: result.content_type,
          response: result.content_type == 'application/pdf' ? 'pdf' : result.body&.truncate(5000),
          http_status: result.status,
        }
        update_log_record(record, attrs)
      end

      [result, record]
    end

    protected

    def new_log_record(...)
      HmisExternalApis::ExternalRequestLog.create!(...)
    end

    def update_log_record(record, attrs)
      # Capture logging to stdout too, because ExternalRequestLog is sometimes being rolled back in transactions
      Rails.logger.info "ExternalRequestLog captured: URL:#{record.url}, REQUEST:#{record.request}, RESPONSE:#{attrs}"
      record.update!(attrs)
    end
  end
end
