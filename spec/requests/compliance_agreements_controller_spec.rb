# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ComplianceAgreementsController, type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:admin_role) }
  let!(:collection) { create(:collection) }
  let!(:content_page) { create(:content_page, title: 'Terms of Service', content: '# Expected H1 Content') }
  let!(:requirement) { create(:compliance_requirement, content_page: content_page, active: true) }

  before do
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'GET #show' do
    context 'when user has pending requirements' do
      it 'displays the requirement content' do
        get compliance_agreement_path
        # expect(response.body).to include('Your Terms')
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Expected H1 Content')
      end
    end

    context 'when user has no pending requirements' do
      before do
        create(:compliance_agreement, user: user, requirement: requirement, revision: requirement.revision)
      end

      it 'redirects to root path' do
        get compliance_agreement_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST #create' do
    context 'when user agrees' do
      it 'creates a compliance agreement' do
        expect do
          post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision, agree: '1' }
        end.to change(GrdaWarehouse::Compliance::Agreement, :count).by(1)
      end

      it 'records the correct revision' do
        post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision, agree: '1' }
        agreement = GrdaWarehouse::Compliance::Agreement.last
        expect(agreement.revision).to eq(requirement.revision)
      end

      context 'with expiration' do
        let!(:requirement) { create(:compliance_requirement, :with_expiration, content_page: content_page) }

        it 'sets expires_at based on requirement' do
          freeze_time do
            post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision, agree: '1' }
            agreement = GrdaWarehouse::Compliance::Agreement.last
            expect(agreement.expires_at).to eq(Time.current + requirement.expires_after_days.days)
          end
        end
      end
    end

    context 'when user does not agree' do
      it 'does not create a compliance agreement' do
        expect do
          post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision, agree: '0' }
        end.not_to change(GrdaWarehouse::Compliance::Agreement, :count)
      end

      it 'renders show with alert' do
        post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision, agree: '0' }
        expect(response).not_to be_redirect
        expect(flash[:alert]).to include('must agree')
      end
    end

    context 'with multiple requirements' do
      let!(:content_page2) { create(:content_page, title: 'Privacy Policy') }
      let!(:requirement2) { create(:compliance_requirement, content_page: content_page2, active: true, position: 1) }

      it 'shows success message for next requirement' do
        post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision, agree: '1' }
        expect(flash[:notice]).to include('next requirement')
      end
    end

    context 'when requirement revision changed after page load' do
      it 'redirects back to show without creating agreement' do
        requirement.update!(revision: requirement.revision + 1)
        expect do
          post compliance_agreement_path, params: { requirement_id: requirement.id, revision: requirement.revision - 1, agree: '1' }
        end.not_to change(GrdaWarehouse::Compliance::Agreement, :count)
        expect(response).to redirect_to(compliance_agreement_path)
        expect(flash[:alert]).to include('updated')
      end
    end
  end
end
