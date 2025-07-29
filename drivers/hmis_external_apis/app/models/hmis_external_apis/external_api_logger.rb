# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ExternalApiLogger
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
        # If an exception occurred, it was a failure to connect. Storing "400" status code to indicate it was on our side (the client)
        update_log_record(record, { response: "#{e.class.name}: #{e.message || 'Unknown error'}", http_status: 400 })
        raise
      end

      if result
        # result is either a Faraday::Response or OAuth2::Response
        content_type = result.respond_to?(:content_type) ? result.content_type : result.headers['content-type']

        attrs = {
          content_type: content_type,
          response: content_type == 'application/pdf' ? 'pdf' : result.body&.truncate(5000),
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
