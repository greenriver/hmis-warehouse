# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ComplianceRequirementsController, type: :request do
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role }
  let!(:no_data_source_collection) { create :collection }

  describe 'GET #index' do
    context 'with authorized user' do
      before(:each) do
        setup_access_control(user, role, no_data_source_collection)
        sign_in user
      end

      it 'returns http success' do
        get admin_compliance_requirements_path
        expect(response).to have_http_status(:success)
      end

      it 'displays existing requirements' do
        requirement = create(:compliance_requirement, name: 'Test Requirement')
        get admin_compliance_requirements_path
        expect(response.body).to include('Test Requirement')
      end
    end

    context 'with unauthorized user' do
      before(:each) do
        sign_in user
      end

      it 'redirects' do
        get admin_compliance_requirements_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'GET #new' do
    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    it 'returns http success' do
      get new_admin_compliance_requirement_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let!(:content_page) { create(:content_page) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'with valid attributes' do
      let(:valid_attrs) { { name: 'Terms of Service', content_page_id: content_page.id, revision: 1 } }

      it 'creates compliance requirement' do
        expect {
          post admin_compliance_requirements_path, params: { compliance_requirement: valid_attrs }
        }.to change(GrdaWarehouse::Compliance::Requirement, :count).by(1)
      end

      it 'redirects to index' do
        post admin_compliance_requirements_path, params: { compliance_requirement: valid_attrs }
        expect(response).to redirect_to(admin_compliance_requirements_path)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attrs) { { name: '', content_page_id: nil } }

      it 'does not create compliance requirement' do
        expect {
          post admin_compliance_requirements_path, params: { compliance_requirement: invalid_attrs }
        }.not_to change(GrdaWarehouse::Compliance::Requirement, :count)
      end

      it 'renders new template' do
        post admin_compliance_requirements_path, params: { compliance_requirement: invalid_attrs }
        expect(response).not_to be_redirect
      end
    end
  end

  describe 'GET #edit' do
    let!(:requirement) { create(:compliance_requirement) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    it 'returns http success' do
      get edit_admin_compliance_requirement_path(requirement)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH #update' do
    let!(:requirement) { create(:compliance_requirement) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'with valid attributes' do
      let(:valid_attrs) { { name: 'Updated Requirement', revision: 2 } }

      it 'updates the compliance requirement' do
        patch admin_compliance_requirement_path(requirement), params: { compliance_requirement: valid_attrs }
        requirement.reload
        expect(requirement.name).to eq('Updated Requirement')
        expect(requirement.revision).to eq(2)
      end

      it 'redirects to index' do
        patch admin_compliance_requirement_path(requirement), params: { compliance_requirement: valid_attrs }
        expect(response).to redirect_to(admin_compliance_requirements_path)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attrs) { { name: '' } }

      it 'does not update the compliance requirement' do
        original_name = requirement.name
        patch admin_compliance_requirement_path(requirement), params: { compliance_requirement: invalid_attrs }
        requirement.reload
        expect(requirement.name).to eq(original_name)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:requirement) { create(:compliance_requirement) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'when requirement has no agreements' do
      it 'deletes the compliance requirement' do
        expect {
          delete admin_compliance_requirement_path(requirement)
        }.to change(GrdaWarehouse::Compliance::Requirement, :count).by(-1)
      end

      it 'redirects to index' do
        delete admin_compliance_requirement_path(requirement)
        expect(response).to redirect_to(admin_compliance_requirements_path)
      end
    end

    context 'when requirement has agreements' do
      let!(:agreeing_user) { create(:user) }
      let!(:agreement) { create(:compliance_agreement, requirement: requirement, user: agreeing_user) }

      it 'does not delete the compliance requirement' do
        expect {
          delete admin_compliance_requirement_path(requirement)
        }.not_to change(GrdaWarehouse::Compliance::Requirement, :count)
      end

      it 'redirects with alert' do
        delete admin_compliance_requirement_path(requirement)
        expect(response).to redirect_to(admin_compliance_requirements_path)
        expect(flash[:alert]).to include('Cannot delete')
      end
    end
  end

  describe 'POST #activate' do
    let!(:requirement) { create(:compliance_requirement, :inactive) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    it 'activates the requirement' do
      post activate_admin_compliance_requirement_path(requirement)
      requirement.reload
      expect(requirement.active).to be true
    end

    it 'redirects to index' do
      post activate_admin_compliance_requirement_path(requirement)
      expect(response).to redirect_to(admin_compliance_requirements_path)
    end
  end

  describe 'POST #deactivate' do
    let!(:requirement) { create(:compliance_requirement, active: true) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    it 'deactivates the requirement' do
      post deactivate_admin_compliance_requirement_path(requirement)
      requirement.reload
      expect(requirement.active).to be false
    end

    it 'redirects to index' do
      post deactivate_admin_compliance_requirement_path(requirement)
      expect(response).to redirect_to(admin_compliance_requirements_path)
    end
  end
end
