###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'oauth2-proxy skip_auth_routes', :jwt_only do
  let(:config_path) { 'docker/auth/dev.oauth2-proxy-warehouse.cfg' }
  let(:skip_patterns) { Oauth2Proxy::Config.load(Rails.root.join(config_path)).skip_auth_routes }
  let(:routes) { Oauth2Proxy::RouteInventory.new.routes }
  let(:open_routes) { routes.select(&:needs_proxy_skip?).reject { |route| route.matched_by?(skip_patterns) } }

  # Served without a user session, and kept behind the proxy on purpose.
  let(:behind_proxy) do
    {
      /\A\/rails\/active_storage\// => 'Drawn only in the test environment; Rack::Attack blocks the prefix in every environment',
      /\A\/rails\/(conductor\/)?action_mailbox\// => 'Loaded by rails/all; the app receives no inbound email',
      /\A\/(404|422|500)\z/ => 'Rendered by exceptions_app inside the failing request',
    }
  end

  # Served without a user session, and behind the proxy on QA. Each needs a decision: add a
  # skip_auth_routes entry here and on QA, or move it to behind_proxy with the reason.
  let(:pending_review) do
    [
      '/users/sign_in',
      '/users/sign_out',
      '/public/pages/:slug',
      '/maintenance',
      '/maintenance_saver',
      '/projects/:project_id/data_quality_reports/:id',
      '/projects/:project_id/data_quality_reports/:id/answers',
      '/project_groups/:project_group_id/data_quality_reports/:id',
      '/project_groups/:project_group_id/data_quality_reports/:id/answers',
      '/notifications/:notification_id/projects/:project_id/data_quality_reports/:id',
      '/notifications/:notification_id/projects/:project_id/data_quality_reports/:id/answers',
      '/notifications/:notification_id/project_groups/:project_group_id/data_quality_reports/:id',
      '/notifications/:notification_id/project_groups/:project_group_id/data_quality_reports/:id/answers',
      '/logo/:logo',
      '/hmis_external_api/ac_hmis/referrals',
      '/hmis_external_api/ac_hmis/program_involvements',
      '/hmis_external_api/ac_hmis/client_involvements',
      '/hmis/system_status/operational',
      '/hmis/system_status/cache_status',
      '/hmis/system_status/details',
      '/hmis/system_status/ping',
      '/hmis/system_status/exception',
      '/hmis/theme',
      '/hmis/themes',
      '/hmis/logout',
      '/clients/:client_id/history/pdf',
    ]
  end

  def allow_listed?(route)
    pending_review.include?(route.path) || behind_proxy.keys.any? { |pattern| pattern.match?(route.path) }
  end

  it 'reads skip entries and classifies routes on both sides of the proxy boundary' do
    public_agencies = routes.find { |route| route.path == '/public_agencies' }
    client = routes.find { |route| route.verb == 'GET' && route.path == '/clients/:id' }

    expect([public_agencies.auth, public_agencies.matched_by?(skip_patterns), client.auth]).to eq([:none, true, :user])
  end

  it 'skips proxy auth for every route the app serves without a user session' do
    uncovered = open_routes.reject { |route| allow_listed?(route) }.map(&:to_s).uniq

    expect(uncovered).to be_empty, <<~MSG
      These routes skip the app's user authentication, but no skip_auth_routes entry in #{config_path} matches them, so oauth2-proxy sends them to sign-in:

      #{uncovered.join("\n")}

      Add a skip_auth_routes entry to #{config_path} and to the deployed oauth2-proxy configs, or add the route to behind_proxy in this spec with the reason it stays behind the proxy.
    MSG
  end

  it 'keeps proxy auth on every route that requires a user session' do
    exposed = routes.select { |route| route.auth == :user && route.matched_by?(skip_patterns) }.map(&:to_s).uniq

    expect(exposed).to be_empty, <<~MSG
      These routes require a user session, but a skip_auth_routes entry in #{config_path} matches them, so oauth2-proxy lets anonymous requests through:

      #{exposed.join("\n")}

      Tighten the matching entry (anchor it, or end it with $) here and in the deployed oauth2-proxy configs.
    MSG
  end

  it 'allow-lists only routes that still skip user auth and match no skip entry' do
    open_paths = open_routes.map(&:path)
    stale = (pending_review - open_paths) +
      behind_proxy.keys.reject { |pattern| open_paths.any? { |path| pattern.match?(path) } }.map(&:inspect)

    expect(stale).to be_empty, "Remove these allow-list entries; they match no open route:\n#{stale.join("\n")}"
  end
end
