###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  OauthClientResult = Struct.new(
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
    keyword_init: true,
  ) do
  end
end
