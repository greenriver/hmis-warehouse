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
      it 'creates a new user and redirects to admin_users_path' do
        expect do
          post :create, params: valid_params, format: :html
        end.to change(User, :count).by(1)

        expect(response).to redirect_to(admin_users_path)
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
  end
end
