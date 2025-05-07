###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Superset::Api provides methods to authenticate with and interact with the Superset REST API.
# It supports checking availability, fetching roles, and handling authentication headers.
class Superset::Api
  # Initializes the Superset::Api instance with credentials and host information from environment variables.
  def initialize
    # For deployments, we can just use the SUPPERSET_FQDN, but local development
    # will use the docker network, so the host will be the docker network name
    fqdn_host = "https://#{ENV['SUPERSET_FQDN']}" if ENV['SUPERSET_FQDN'].present?

    @host = ENV.fetch('SUPERSET_HOST', fqdn_host)
    @api_suffix = '/api/v1'
    @username = ENV['SUPERSET_USERNAME']
    @password = ENV['SUPERSET_PASSWORD']
    @provider = 'db'
  end

  # Returns true if all required environment variables are present.
  def available?
    @host && @username && @password
  end

  # Performs a GET request to the given API path with optional query parameters.
  # @param path [String] the API endpoint path
  # @param query [Hash] optional query parameters
  # @return [Curl::Easy] the HTTP response object
  def get(path, query = {})
    # TODO: error handling
    Curl.get(
      construct_url(path) + "?#{query.to_query}",
    ) do |curl|
      curl.headers = session_headers
    end
  end

  # Returns the list of roles, fetching them from the API if not already cached.
  # @return [Array<Hash>] the list of roles
  def roles
    @roles ||= fetch_roles
  end

  # Fetches the list of roles from the Superset API.
  # @return [Array<Hash>] the parsed JSON response containing roles
  private def fetch_roles
    path = '/security/roles/'
    query = {
      'page' => 0,
      'page_size' => 100,
    }
    response = get(path, query)
    JSON.parse(response.body)
  end

  # Builds the default headers for API requests, including the Authorization token.
  # @return [Hash] the headers hash
  private def default_headers
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json',
    }
  end

  # Retrieves and caches the access token by logging in to Superset.
  # @return [String] the access token
  private def access_token
    @access_token ||= JSON.parse(login.body)['access_token']
  end

  # Builds and caches session headers, including Origin and Authorization.
  # @return [Hash] the session headers hash
  private def session_headers
    @session_headers ||= default_headers.merge(
      'Origin' => @host,
    )
  end

  # Fetches and caches the CSRF token from Superset.
  # @return [Curl::Easy] the HTTP response object containing the CSRF token
  private def csrf_token
    @csrf_token ||= Curl.get(
      construct_url('/security/csrf_token/'),
    ) do |curl|
      curl.headers = default_headers
    end
  end

  # Authenticates with Superset and returns the HTTP response.
  # The response body should contain the access token.
  # @return [Curl::Easy] the HTTP response object
  private def login
    Curl.post(
      construct_url('/security/login'),
      {
        username: @username,
        password: @password,
        provider: @provider,
        refresh: true,
      }.to_json,
    ) do |curl|
      curl.headers['Content-Type'] = 'application/json'
    end
  end

  # Constructs a full API URL for a given endpoint path.
  # @param path [String] the API endpoint path
  # @return [String] the full URL
  private def construct_url(path)
    path = path.delete_prefix('/')
    "#{@host}#{@api_suffix}/#{path}"
  end
end
