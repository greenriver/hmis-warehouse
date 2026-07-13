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
    allow(Sentry).to receive(:initialized?).and_return(true)
    allow(Sentry).to receive(:capture_exception_with_info)
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

      it 'checks for a Doorkeeper::Application configured for the Superset redirect URI' do
        a_t = Doorkeeper::Application.arel_table
        relation = instance_double(ActiveRecord::Relation, exists?: true)
        allow(Doorkeeper::Application).to receive(:where).with(a_t[:redirect_uri].matches("%#{described_class.superset_base_url}%")).and_return(relation)

        expect(described_class.available?).to eq(true)
      end

      it 'is unavailable with no matching Doorkeeper::Application' do
        relation = instance_double(ActiveRecord::Relation, exists?: false)
        allow(Doorkeeper::Application).to receive(:where).and_return(relation)

        expect(described_class.available?).to eq(false)
      end
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
      before do
        allow(api).to receive(:available?).and_return(true)
        allow(api).to receive(:roles).and_raise(Curl::Err::HostResolutionError.new('could not resolve'))
      end

      it 'returns default roles' do
        expect(described_class.available_superset_roles).to eq(described_class.default_roles)
      end
    end

    context 'when Superset is configured but API returns unparseable JSON' do
      before do
        allow(api).to receive(:available?).and_return(true)
        allow(api).to receive(:roles).and_raise(JSON::ParserError.new('unexpected token'))
      end

      it 'returns default roles' do
        expect(described_class.available_superset_roles).to eq(described_class.default_roles)
      end
    end
  end
end
