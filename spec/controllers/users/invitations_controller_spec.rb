###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::InvitationsController, type: :controller do
  let(:admin_user) { create(:acl_user) }
  let(:admin_role) { create :admin_role }
  let(:no_data_source_collection) { create :collection }

  let(:agency) { create(:agency) }
  let(:valid_params) do
    {
      user: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        phone: '123-456-7890',
        agency_id: agency.id,
        legacy_role_ids: [],
        user_group_ids: [],
      },
    }
  end

  let(:invalid_params) do
    {
      user: {
        email: '',
        first_name: '',
        last_name: '',
      },
    }
  end

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in admin_user
    setup_access_control(admin_user, admin_role, no_data_source_collection)
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new user and redirects to edit_admin_user_path' do
        expect do
          post :create, params: valid_params, format: :html
        end.to change(User, :count).by(1)

        expect(response).to redirect_to(edit_admin_user_path(User.last))
        expect(flash[:notice]).to eq('An invitation email has been sent to john.doe@example.com.')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new user and re-renders the new template' do
        expect do
          post :create, params: invalid_params, format: :html
        end.not_to change(User, :count)

        expect(response).to render_template(:new)
        expect(assigns(:user).errors).not_to be_empty
      end
    end

    context 'with duplicate email (existing active user)' do
      let!(:existing_user) { create(:user, email: 'existing@example.com', agency: agency) }
      let(:duplicate_email_params) do
        valid_params.deep_merge(user: { email: existing_user.email })
      end

      it 're-renders new template without raising (partial lookup and @system_alerts)' do
        expect do
          post :create, params: duplicate_email_params, format: :html
        end.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
        expect(assigns(:user).errors).not_to be_empty
      end
    end
  end
end
