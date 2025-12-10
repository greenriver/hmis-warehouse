# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ContentPagesController, type: :request do
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
        get admin_content_pages_path
        expect(response).to have_http_status(:success)
      end

      it 'displays existing content pages' do
        create(:content_page, title: 'Test Page')
        get admin_content_pages_path
        expect(response.body).to include('Test Page')
      end
    end

    context 'with unauthorized user' do
      before(:each) do
        sign_in user
      end

      it 'redirects' do
        get admin_content_pages_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'POST #create' do
    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'with valid attributes' do
      let(:valid_attrs) { { title: 'New Page', content: 'Page content here' } }

      it 'creates content page' do
        expect do
          post admin_content_pages_path, params: { content_page: valid_attrs }
        end.to change(GrdaWarehouse::ContentPage, :count).by(1)
      end

      it 'redirects to index' do
        post admin_content_pages_path, params: { content_page: valid_attrs }
        expect(response).to redirect_to(admin_content_pages_path)
      end

      it 'auto-generates slug from title' do
        post admin_content_pages_path, params: { content_page: valid_attrs }
        expect(GrdaWarehouse::ContentPage.last.slug).to eq('new_page')
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attrs) { { title: '', content: '' } }

      it 'does not create content page' do
        expect do
          post admin_content_pages_path, params: { content_page: invalid_attrs }
        end.not_to change(GrdaWarehouse::ContentPage, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:content_page) { create(:content_page) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'with valid attributes' do
      let(:valid_attrs) { { title: 'Updated Title', content: 'Updated content' } }

      it 'updates the content page' do
        patch admin_content_page_path(content_page), params: { content_page: valid_attrs }
        content_page.reload
        expect(content_page.title).to eq('Updated Title')
      end

      it 'redirects to index' do
        patch admin_content_page_path(content_page), params: { content_page: valid_attrs }
        expect(response).to redirect_to(admin_content_pages_path)
      end

      it 'sets updated_by to current user' do
        patch admin_content_page_path(content_page), params: { content_page: valid_attrs }
        content_page.reload
        expect(content_page.updated_by).to eq(user)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attrs) { { title: '', content: '' } }

      it 'does not update the content page' do
        original_title = content_page.title
        patch admin_content_page_path(content_page), params: { content_page: invalid_attrs }
        content_page.reload
        expect(content_page.title).to eq(original_title)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:content_page) { create(:content_page) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'when page has no compliance requirements' do
      it 'deletes the content page' do
        expect do
          delete admin_content_page_path(content_page)
        end.to change(GrdaWarehouse::ContentPage, :count).by(-1)
      end
    end

    context 'when page has compliance requirements' do
      let!(:requirement) { create(:compliance_requirement, content_page: content_page) }

      it 'does not delete the content page' do
        expect do
          delete admin_content_page_path(content_page)
        end.not_to change(GrdaWarehouse::ContentPage, :count)
      end
    end
  end
end
