# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentPagesController, type: :request do
  describe 'GET #show' do
    let!(:content_page) { create(:content_page, title: 'Terms of Service', slug: 'terms_of_service') }

    context 'without authentication' do
      it 'allows access to content pages' do
        get content_page_path(content_page.slug)
        expect(response).to have_http_status(:success)
      end

      it 'displays the page content' do
        get content_page_path(content_page.slug)
        expect(response.body).to include('Terms of Service')
      end
    end

    context 'with authentication' do
      let!(:user) { create(:acl_user) }

      before do
        sign_in user
      end

      it 'allows access to content pages' do
        get content_page_path(content_page.slug)
        expect(response).to have_http_status(:success)
      end
    end

    context 'with non-existent page' do
      it 'returns 404' do
        get content_page_path('non_existent_page')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

