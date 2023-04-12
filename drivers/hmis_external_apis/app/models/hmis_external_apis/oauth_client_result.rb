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
    keyword_init: true,
  ) do
  end
end
