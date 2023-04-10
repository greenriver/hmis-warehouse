module HmisExternalApis
  OauthClientResult = Struct.new(
    :body,
    :content_type,
    :error,
    :error_type,
    :http_method,
    :ip,
    :parsed_body,
    :request,
    :request_headers,
    :status,
    keyword_init: true,
  ) do
  end
end
