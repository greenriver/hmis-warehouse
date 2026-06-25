###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis
  ExternalApiResult = Struct.new(
    :body,
    :content_type,
    :error,
    :error_type,
    :http_method,
    :ip,
    :parsed_body,
    :request_headers,
    :http_status,
    :url,
    :request_body,
    :request_log,
    keyword_init: true,
  ) do
  end
end
