###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'oauth2-proxy skip_auth_routes', :jwt_only do
  let(:warehouse_config_path) { 'docker/auth/dev.oauth2-proxy-warehouse.cfg' }
  let(:hmis_config_path) { 'docker/auth/dev.oauth2-proxy-hmis-backend.cfg' }
  let(:skip_patterns) do
    [warehouse_config_path, hmis_config_path].index_with do |path|
      Oauth2Proxy::Config.load(Rails.root.join(path)).skip_auth_routes
    end
  end
  let(:routes) { Oauth2Proxy::RouteInventory.new.routes }
  let(:open_routes) do
    routes.select(&:needs_proxy_skip?).reject { |route| route.matched_by?(skip_patterns[config_path_for(route)]) }
  end

  # Served without a user session, and kept behind the proxy on purpose.
  let(:behind_proxy) do
    {
      /\A\/rails\/active_storage\// => 'Drawn only in the test environment; Rack::Attack blocks the prefix in every environment',
      /\A\/rails\/(conductor\/)?action_mailbox\// => 'Loaded by rails/all; the app receives no inbound email',
      /\A\/(404|422|500)\z/ => 'Rendered by exceptions_app inside the failing request',
      /\A(\/notifications\/:notification_id)?\/(projects\/:project_id|project_groups\/:project_group_id)\/data_quality_reports\/:id(\/answers)?\z/ =>
        'Legacy data quality reports, slated for removal; not opened at the proxy',
      /\A\/users\/sign_in\z/ => 'Only redirects to the oauth2-proxy sign-in, which the proxy does on its own',
      /\A\/(users\/sign_out|hmis\/logout)\z/ =>
        'Ends the IdP session with the access token oauth2-proxy forwards; skips user auth only so deactivated users can sign out',
      /\A\/hmis\/system_status\// => 'Same actions as /system_status/, which the warehouse host opens',
      /\A\/clients\/:client_id\/history\/pdf\z/ =>
        'No HTTP caller; ClientHistory#generate_service_history_pdf renders the template in-process',
    }
  end

  # The HMIS backend host serves /hmis/; the warehouse host serves everything else.
  def config_path_for(route)
    route.path.start_with?('/hmis/') ? hmis_config_path : warehouse_config_path
  end

  def behind_proxy?(route)
    behind_proxy.keys.any? { |pattern| pattern.match?(route.path) }
  end

  it 'reads skip entries and classifies routes on both sides of the proxy boundary' do
    public_agencies = routes.find { |route| route.path == '/public_agencies' }
    client = routes.find { |route| route.verb == 'GET' && route.path == '/clients/:id' }
    hmis_theme = routes.find { |route| route.path == '/hmis/theme' }

    expect(
      [
        public_agencies.auth,
        public_agencies.matched_by?(skip_patterns[warehouse_config_path]),
        client.auth,
        hmis_theme.matched_by?(skip_patterns[hmis_config_path]),
      ],
    ).to eq([:none, true, :user, true])
  end

  it 'skips proxy auth for every route the app serves without a user session' do
    uncovered = open_routes.reject { |route| behind_proxy?(route) }.map { |route| "#{route} in #{config_path_for(route)}" }.uniq

    expect(uncovered).to be_empty, <<~MSG
      These routes skip the app's user authentication, but no skip_auth_routes entry in their host's config matches them, so oauth2-proxy sends them to sign-in:

      #{uncovered.join("\n")}

      Add a skip_auth_routes entry to that config and to the deployed oauth2-proxy configs, or add the route to behind_proxy in this spec with the reason it stays behind the proxy.
    MSG
  end

  # Every host reaches every route, so each config is checked against all of them.
  it 'keeps proxy auth on every route that requires a user session' do
    exposed = skip_patterns.flat_map do |path, patterns|
      routes.select { |route| route.auth == :user && route.matched_by?(patterns) }.map { |route| "#{route} in #{path}" }
    end.uniq

    expect(exposed).to be_empty, <<~MSG
      These routes require a user session, but a skip_auth_routes entry matches them, so oauth2-proxy lets anonymous requests through:

      #{exposed.join("\n")}

      Tighten the matching entry (anchor it, or end it with $) here and in the deployed oauth2-proxy configs.
    MSG
  end

  it 'allow-lists only routes that still skip user auth and match no skip entry' do
    open_paths = open_routes.map(&:path)
    stale = behind_proxy.keys.reject { |pattern| open_paths.any? { |path| pattern.match?(path) } }.map(&:inspect)

    expect(stale).to be_empty, "Remove these behind_proxy entries; they match no open route:\n#{stale.join("\n")}"
  end
end
