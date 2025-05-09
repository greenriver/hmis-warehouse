# frozen_string_literal: true

RSpec.shared_context "client search helpers" do
  # Perform a search via POST and return response and parsed doc
  def post_search_query(params = {}, follow_redirect: true)
    post client_search_queries_path, params: params
    follow_redirect! if follow_redirect
    [response, Nokogiri::HTML(response.body)]
  end

  # Handle legacy search pattern with automatic redirect following
  def get_search_legacy(params)
    get clients_path, params: params
    follow_redirect!
    [response, Nokogiri::HTML(response.body)]
  end

  # Create a search query and return it
  def create_search_query(params, user: nil)
    target_user = user || (defined?(current_user) ? current_user : nil)
    create(:grda_warehouse_client_search_query,
           created_by: target_user,
           params: params)
  end

  # Get search results using a query ID
  def view_search_results(query)
    get client_search_query_path(id: query.encrypted_id)
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
