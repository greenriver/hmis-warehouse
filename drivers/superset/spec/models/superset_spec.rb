###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Superset do
  let(:api) { instance_double(Superset::Api) }

  before do
    allow(Superset::Api).to receive(:new).and_return(api)
  end

  describe '.superset_base_url' do
    it 'splices "superset" into the FQDN when SUPERSET_FQDN is unset' do
      # SUPERSET_FQDN is unset in the test env, so the second fetch falls through to the
      # spliced default; only FQDN needs stubbing.
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('FQDN', anything).and_return('warehouse.example.org')

      expect(described_class.superset_base_url).to eq('https://warehouse.superset.example.org')
    end

    it 'uses SUPERSET_FQDN verbatim when set' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SUPERSET_FQDN', anything).and_return('dashboards.example.org')

      expect(described_class.superset_base_url).to eq('https://dashboards.example.org')
    end
  end

  describe '.warehouse_login_url' do
    it 'points at the URL-encoded warehouse login provider path' do
      allow(described_class).to receive(:superset_base_url).and_return('https://superset.example.test')

      expect(described_class.warehouse_login_url).to eq('https://superset.example.test/login/The%20Warehouse')
    end
  end

  describe '.available?' do
    context 'under AuthMethod.jwt?' do
      before { allow(AuthMethod).to receive(:jwt?).and_return(true) }

      it 'is unavailable when SUPERSET_ADMIN_PASS is unset' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SUPERSET_ADMIN_PASS').and_return(nil)

        expect(described_class.available?).to eq(false)
      end

      it 'is available in development as soon as a password is set, even the insecure default' do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SUPERSET_ADMIN_PASS').and_return('admin')

        expect(described_class.available?).to eq(true)
      end

      it 'is unavailable outside development when the password is still the insecure default' do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SUPERSET_ADMIN_PASS').and_return('admin')

        expect(described_class.available?).to eq(false)
      end

      it 'is available outside development when a non-default password is set' do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SUPERSET_ADMIN_PASS').and_return('a-real-password')

        expect(described_class.available?).to eq(true)
      end
    end

    context 'under AuthMethod.devise?' do
      before { allow(AuthMethod).to receive(:jwt?).and_return(false) }

      it 'is available when a Doorkeeper::Application is registered for the Superset host' do
        Doorkeeper::Application.create!(
          name: 'Superset',
          redirect_uri: "#{described_class.superset_base_url}/oauth/authorize",
        )

        expect(described_class.available?).to eq(true)
      end

      it 'is unavailable when the only registered Doorkeeper::Application points elsewhere' do
        Doorkeeper::Application.create!(
          name: 'Unrelated',
          redirect_uri: 'https://unrelated.example.test/oauth/authorize',
        )

        expect(described_class.available?).to eq(false)
      end
    end
  end

  describe '.available_to_user?' do
    # The report definition the Superset gate keys off of; present in every example so that a
    # `false` result is attributable to the authorization scope, not to missing data.
    let!(:report_definition) { create(:op_analytics_report) }
    let(:user) { create(:acl_user) }
    let(:role) { create(:role, can_view_assigned_reports: true) }
    let(:collection) { create(:collection) }

    # Isolate the per-user authorization decision; .available? has its own coverage above.
    before { allow(described_class).to receive(:available?).and_return(true) }

    it 'is available to a user granted access to the Superset report definition' do
      setup_access_control(user, role, collection)
      collection.set_viewables({ reports: [report_definition.id] })

      expect(described_class.available_to_user?(user)).to eq(true)
    end

    it 'is unavailable to a user who has not been granted the Superset report definition' do
      # report_definition exists but is granted to no one, so only the viewable_by(user)
      # guard — not absent data — makes this false.
      expect(described_class.available_to_user?(user)).to eq(false)
    end

    it 'is unavailable when Superset itself is unavailable, even for a permitted user' do
      setup_access_control(user, role, collection)
      collection.set_viewables({ reports: [report_definition.id] })
      allow(described_class).to receive(:available?).and_return(false)

      expect(described_class.available_to_user?(user)).to eq(false)
    end
  end

  describe '.available_superset_roles' do
    context 'when Superset is not configured' do
      before { allow(api).to receive(:available?).and_return(false) }

      it 'returns default roles without making API calls' do
        expect(api).not_to receive(:roles)
        expect(described_class.available_superset_roles).to eq(described_class.default_roles)
      end
    end

    context 'when Superset is configured and API returns roles' do
      before do
        allow(api).to receive(:available?).and_return(true)
        allow(api).to receive(:roles).and_return(
          'result' => [
            { 'name' => 'Green River Admin' },
            { 'name' => 'Report Runner' },
            { 'name' => 'Admin' },
            { 'name' => 'Public' },
          ],
        )
      end

      it 'returns roles excluding ignored ones' do
        roles = described_class.available_superset_roles
        expect(roles).to contain_exactly('Green River Admin', 'Report Runner')
      end
    end

    context 'when Superset is configured but API returns no valid roles' do
      before do
        allow(api).to receive(:available?).and_return(true)
        allow(api).to receive(:roles).and_return(
          'result' => [{ 'name' => 'Admin' }, { 'name' => 'Public' }],
        )
      end

      it 'falls back to default roles' do
        expect(described_class.available_superset_roles).to eq(described_class.default_roles)
      end
    end

    context 'when Superset is configured but API raises HostResolutionError' do
      let(:error) { Curl::Err::HostResolutionError.new('could not resolve') }

      before do
        allow(api).to receive(:available?).and_return(true)
        allow(api).to receive(:roles).and_raise(error)
      end

      it 'reports the error and returns default roles' do
        expect(UnifiedErrorReporter).to receive(:call).with(error, a_string_matching(/Superset roles/))
        expect(described_class.available_superset_roles).to eq(described_class.default_roles)
      end
    end

    context 'when Superset is configured but API returns unparseable JSON' do
      let(:error) { JSON::ParserError.new('unexpected token') }

      before do
        allow(api).to receive(:available?).and_return(true)
        allow(api).to receive(:roles).and_raise(error)
      end

      it 'reports the error and returns default roles' do
        expect(UnifiedErrorReporter).to receive(:call).with(error, a_string_matching(/Superset roles/))
        expect(described_class.available_superset_roles).to eq(described_class.default_roles)
      end
    end
  end
end
