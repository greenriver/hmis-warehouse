###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::NullService, type: :model do
  let(:service) { described_class.new }

  describe '#create_user' do
    it 'raises ServiceError' do
      expect do
        service.create_user(
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
        )
      end.to raise_error(Idp::ServiceError, /User management not supported/)
    end
  end

  describe '#update_user' do
    it 'raises ServiceError' do
      expect do
        service.update_user(
          user_id: 'user-123',
          attributes: { first_name: 'John' },
        )
      end.to raise_error(Idp::ServiceError, /Profile updates not supported/)
    end
  end

  describe '#get_user' do
    it 'raises ServiceError' do
      expect do
        service.get_user(user_id: 'user-123')
      end.to raise_error(Idp::ServiceError, /User lookup not supported/)
    end
  end

  describe '#reactivate_user' do
    it 'raises ServiceError' do
      expect do
        service.reactivate_user(user_id: 'user-123')
      end.to raise_error(Idp::ServiceError, /User reactivation not supported/)
    end
  end

  describe '#idp_name' do
    it 'returns Unknown IDP when no connector_id' do
      expect(service.idp_name).to eq('Unknown IDP')
    end

    it 'humanizes connector_id when provided' do
      service_with_connector = described_class.new('keycloak')
      expect(service_with_connector.idp_name).to eq('Keycloak')
    end
  end

  describe '#supports_user_management?' do
    it 'returns false' do
      expect(service.supports_user_management?).to be false
    end
  end

  describe '#supports_profile_updates?' do
    it 'returns false' do
      expect(service.supports_profile_updates?).to be false
    end
  end

  describe '#account_console_url' do
    it 'returns nil' do
      expect(service.account_console_url).to be_nil
    end
  end

  describe 'initialization' do
    it 'accepts optional connector_id' do
      service = described_class.new('custom_idp')
      expect(service.connector_id).to eq('custom_idp')
    end

    it 'has empty config' do
      expect(service.config).to eq({})
    end
  end
end

RSpec.describe Idp::Service, type: :model do
  describe '#account_console_url' do
    it 'defaults to nil on the base contract' do
      expect(described_class.new.account_console_url).to be_nil
    end
  end
end
