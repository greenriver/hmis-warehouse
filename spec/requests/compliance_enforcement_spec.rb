# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Compliance Agreement Enforcement', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:admin_role) }
  let!(:collection) { create(:collection) }

  before do
    setup_access_control(user, role, collection)
  end

  describe 'when user has pending compliance requirements' do
    let!(:content_page) { create(:content_page) }
    let!(:requirement) { create(:compliance_requirement, content_page: content_page, active: true) }

    it 'redirects authenticated user to compliance agreement page' do
      sign_in user
      get root_path
      expect(response).to redirect_to(compliance_agreement_path)
    end

    it 'stores the original location for redirect after agreement' do
      sign_in user
      get admin_configs_path
      expect(response).to redirect_to(compliance_agreement_path)
    end

    it 'allows access to account pages' do
      sign_in user
      get edit_account_path
      expect(response).not_to redirect_to(compliance_agreement_path)
    end

    it 'allows access to the compliance agreement page itself' do
      sign_in user
      get compliance_agreement_path
      expect(response).to have_http_status(:success)
    end

    it 'allows access to content pages' do
      sign_in user
      get content_page_path(content_page.slug)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'when user has no pending compliance requirements' do
    it 'allows normal access' do
      sign_in user
      get root_path
      expect(response).not_to redirect_to(compliance_agreement_path)
    end
  end

  describe 'when requirement is inactive' do
    let!(:content_page) { create(:content_page) }
    let!(:requirement) { create(:compliance_requirement, :inactive, content_page: content_page) }

    it 'does not block user access' do
      sign_in user
      get root_path
      expect(response).not_to redirect_to(compliance_agreement_path)
    end
  end

  describe 'when user has already agreed' do
    let!(:content_page) { create(:content_page) }
    let!(:requirement) { create(:compliance_requirement, content_page: content_page, active: true) }

    before do
      create(:compliance_agreement, user: user, requirement: requirement, revision: requirement.revision)
    end

    it 'allows normal access' do
      sign_in user
      get root_path
      expect(response).not_to redirect_to(compliance_agreement_path)
    end
  end

  describe 'when agreement is expired' do
    let!(:content_page) { create(:content_page) }
    let!(:requirement) { create(:compliance_requirement, content_page: content_page, active: true) }

    before do
      create(:compliance_agreement, :expired, user: user, requirement: requirement, revision: requirement.revision)
    end

    it 'redirects to compliance agreement page' do
      sign_in user
      get root_path
      expect(response).to redirect_to(compliance_agreement_path)
    end
  end

  describe 'when requirement revision has been bumped' do
    let!(:content_page) { create(:content_page) }
    let!(:requirement) { create(:compliance_requirement, content_page: content_page, active: true, revision: 2) }

    before do
      # User agreed to revision 1, but requirement is now at revision 2
      create(:compliance_agreement, user: user, requirement: requirement, revision: 1)
    end

    it 'redirects to compliance agreement page for new revision' do
      sign_in user
      get root_path
      expect(response).to redirect_to(compliance_agreement_path)
    end
  end
end
