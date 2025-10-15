# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::FormDefinitionPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'draft') }
  let(:policy) { user.policy_for(form_definition, policy_type: :form_definition) }
  let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_view_clients]) }

  shared_examples 'allows non-admin form roles' do
    it 'returns true for SERVICE forms' do
      form_definition.update(role: 'SERVICE')
      expect(policy.can_manage_form?).to be true
    end

    it 'returns true for CUSTOM_ASSESSMENT forms' do
      form_definition.update(role: 'CUSTOM_ASSESSMENT')
      expect(policy.can_manage_form?).to be true
    end
  end

  shared_examples 'always blocks version controlled forms' do
    it 'returns false for managed in version control forms' do
      form_definition.update(managed_in_version_control: true)
      expect(policy.can_manage_form?).to be false
    end
  end

  describe '#can_manage_form?' do
    context 'when user has no permissions' do
      it 'returns false' do
        expect(policy.can_manage_form?).to be false
      end
    end

    context 'when user has can_manage_forms but not can_administrate_config permission' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms]) }

      include_examples 'allows non-admin form roles'
      include_examples 'always blocks version controlled forms'

      it 'returns false for system forms' do
        form_definition.update(role: 'CLIENT')
        expect(policy.can_manage_form?).to be false
      end

      it 'returns false for admin-editable-only forms' do
        form_definition.update(admin_editable_only: true)
        expect(policy.can_manage_form?).to be false
      end
    end

    context 'when user has can_administrate_config permission' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_administrate_config]) }

      include_examples 'allows non-admin form roles'
      include_examples 'always blocks version controlled forms'

      it 'returns true for system forms' do
        form_definition.update(role: 'CLIENT')
        expect(policy.can_manage_form?).to be true
      end

      it 'returns true for admin-editable-only forms' do
        form_definition.update(admin_editable_only: true)
        expect(policy.can_manage_form?).to be true
      end
    end
  end
end
