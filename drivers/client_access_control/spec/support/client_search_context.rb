# frozen_string_literal: true

RSpec.shared_context 'client search helpers' do
  # Perform a search via POST and return response and parsed doc
  def post_search_query(params = {}, follow_redirect: true)
    post client_search_queries_path, params: params
    follow_redirect! if follow_redirect
    [response, Nokogiri::HTML(response.body)]
  end

  # Extract and decrypt the redirected query ID
  def decrypted_redirect_id(response)
    uri = URI(response.location)
    match = /\A\/client_searches\/([^\/]+)\z/.match(uri.path)
    raise "Unexpected redirect path: #{uri.path}" unless match

    encrypted_id = match[1]
    GrdaWarehouse::ClientSearchQueryIdProtector.instance.decrypt(encrypted_id)
  end
end
