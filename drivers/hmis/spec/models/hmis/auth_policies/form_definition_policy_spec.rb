# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::FormDefinitionPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'draft', data_source: data_source) }
  let(:policy) { user.policy_for(form_definition, policy_type: :form_definition) }
  let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_view_clients]) }

  describe 'Instance' do
    describe '#can_manage_form? and other form management permissions' do
      shared_examples 'returns false' do
        it 'returns false' do
          expect(policy.can_manage_form?).to be false
          expect(policy.can_create_draft?).to be false
          expect(policy.can_edit_draft?).to be false
          expect(policy.can_publish?).to be false
          expect(policy.can_delete?).to be false
        end
      end

      shared_examples 'returns true' do
        it 'returns true' do
          expect(policy.can_manage_form?).to be true
          expect(policy.can_create_draft?).to be true
          expect(policy.can_edit_draft?).to be true
          expect(policy.can_publish?).to be true
          expect(policy.can_delete?).to be true
        end
      end

      context 'when the user does not have permission' do
        include_examples 'returns false'
      end

      context 'when the user has permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection]) }
        include_examples 'returns true'

        context 'when the form is managed in version control' do
          let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'draft', managed_in_version_control: true, data_source: data_source) }
          include_examples 'returns false'
        end

        context 'when the form is admin-editable-only' do
          let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'draft', admin_editable_only: true, data_source: data_source) }
          include_examples 'returns false'
        end

        context 'when the form is a super-admin-only form role' do
          let(:form_definition) { create(:hmis_form_definition, role: 'CE_REFERRAL_STEP', status: 'draft', data_source: data_source) }
          include_examples 'returns false'

          context 'when the user has can_administrate_config permission' do
            let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection, :can_administrate_config]) }
            include_examples 'returns true'
          end
        end

        context 'when the form is published' do
          let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'published', data_source: data_source) }

          it 'disallows deletion' do
            expect(policy.can_delete?).to be false
          end
        end
      end
    end

    describe '#can_duplicate?' do
      it 'returns false when the user does not have permission' do
        expect(policy.can_duplicate?).to be false
      end

      context 'when the user has permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection]) }
        it 'returns true' do
          expect(policy.can_duplicate?).to be true
        end

        context 'when the form is managed in version control' do
          let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'draft', managed_in_version_control: true, data_source: data_source) }
          it 'returns true' do
            expect(policy.can_duplicate?).to be true
          end
        end

        context 'when the form is admin-editable-only' do
          let(:form_definition) { create(:hmis_form_definition, role: 'SERVICE', status: 'draft', admin_editable_only: true, data_source: data_source) }
          it 'returns true' do
            expect(policy.can_duplicate?).to be true
          end
        end

        context 'when the form is a super-admin-only form role' do
          let(:form_definition) { create(:hmis_form_definition, role: 'CE_REFERRAL_STEP', data_source: data_source) }
          it 'returns false' do
            expect(policy.can_duplicate?).to be false
          end

          context 'when the user has can_administrate_config permission' do
            let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection, :can_administrate_config]) }
            it 'returns true' do
              expect(policy.can_duplicate?).to be true
            end
          end
        end
      end
    end

    describe '#can_view? and form rule management permissions' do
      shared_examples 'returns false' do
        it 'returns false' do
          expect(policy.can_view?).to be false
          expect(policy.can_add_form_rule?).to be false
          expect(policy.can_delete_form_rule?).to be false
        end
      end

      shared_examples 'returns true' do
        it 'returns true' do
          expect(policy.can_view?).to be true
          expect(policy.can_add_form_rule?).to be true
          expect(policy.can_delete_form_rule?).to be true
        end
      end

      context 'when the user does not have permission' do
        include_examples 'returns false'
      end

      context 'when the user has permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection]) }
        include_examples 'returns true'
      end

      context 'when the form is a super-admin-only form role' do
        let(:form_definition) { create(:hmis_form_definition, role: 'CE_REFERRAL_STEP', data_source: data_source) }
        include_examples 'returns false'

        context 'when the user has can_administrate_config permission' do
          let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection, :can_manage_forms, :can_administrate_config]) }
          include_examples 'returns true'
        end
      end
    end
  end

  describe 'Global' do
    let(:policy) { user.policy_for(Hmis::Form::Definition, policy_type: :form_definition) }

    describe '#can_create?' do
      context 'when user has can_manage_forms permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection]) }
        it 'returns true for non-super-admin form roles' do
          expect(policy.can_create?(role: 'SERVICE')).to be true
          expect(policy.can_create?(role: 'CUSTOM_ASSESSMENT')).to be true
        end

        it 'returns false for super-admin form roles' do
          expect(policy.can_create?(role: 'CE_REFERRAL_STEP')).to be false
          expect(policy.can_create?(role: 'CURRENT_LIVING_SITUATION')).to be false
        end

        it 'returns false when role is nil' do
          expect(policy.can_create?(role: nil)).to be false
        end

        it 'returns false when role is invalid' do
          expect(policy.can_create?(role: 'NOT_A_ROLE')).to be false
        end
      end

      context 'when user has can_administrate_config permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection, :can_administrate_config]) }
        it 'returns true for all form roles' do
          expect(policy.can_create?(role: 'SERVICE')).to be true
          expect(policy.can_create?(role: 'CUSTOM_ASSESSMENT')).to be true
          expect(policy.can_create?(role: 'CE_REFERRAL_STEP')).to be true
          expect(policy.can_create?(role: 'CURRENT_LIVING_SITUATION')).to be true
        end
      end

      context 'when user has can_administrate_config but not can_manage_forms permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_administrate_config]) }

        it 'returns false' do
          expect(policy.can_create?(role: 'SERVICE')).to be false
          expect(policy.can_create?(role: 'CE_REFERRAL_STEP')).to be false
        end
      end

      context 'when user does not have can_manage_forms permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_view_clients]) }

        it 'returns false for all form roles' do
          expect(policy.can_create?(role: 'CUSTOM_ASSESSMENT')).to be false
          expect(policy.can_create?(role: 'CURRENT_LIVING_SITUATION')).to be false
        end
      end
    end

    describe '#can_manage_forms?' do
      it 'returns false when user does not have can_manage_forms permission' do
        expect(policy.can_manage_forms?).to be false
      end

      context 'when user has can_manage_forms permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_manage_forms, :can_configure_data_collection]) }

        it 'returns true' do
          expect(policy.can_manage_forms?).to be true
        end
      end
    end

    describe '#can_index? and #can_manage_form_rules?' do
      it 'returns false when user does not have can_configure_data_collection permission' do
        expect(policy.can_index?).to be false
        expect(policy.can_manage_form_rules?).to be false
      end

      context 'when user has can_configure_data_collection permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection]) }

        it 'returns true' do
          expect(policy.can_index?).to be true
          expect(policy.can_manage_form_rules?).to be true
        end
      end
    end

    describe '#can_administrate_config?' do
      it 'returns false when user does not have can_administrate_config permission' do
        expect(policy.can_administrate_config?).to be false
      end

      context 'when user has can_administrate_config permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_administrate_config, :can_manage_forms, :can_configure_data_collection]) }

        it 'returns true' do
          expect(policy.can_administrate_config?).to be true
        end
      end
    end
  end
end
