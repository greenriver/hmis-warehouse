###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# IdP-backed admin account provisioning, shared by the warehouse (Admin::Idp::UsersController)
# and HMIS (HmisAdmin::UsersController) arms — the controller behavior that Admin::Idp::UserCreation
# mixes into both. Only exists under AUTH_METHOD=jwt, where Idp::Support is mixed into the user
# model and the new/create routes are mounted.
#
# The including group must:
#   * include_context 'with a creation-capable IdP connector' (Keycloak/WebMock scaffolding)
#   * sign in an admin authorized to create users
#   * define these, matching the controller's UserCreation template methods:
#       user_class        the model provisioned (User / Hmis::User)
#       users_index_path  the index url (also the create POST target)
#       create_form_path  the new url
#       next_step_pattern regex the success notice's trailing instruction should match
#       edit_path_for(user) helper returning the post-create edit url
RSpec.shared_examples 'admin IdP-backed user creation' do
  let(:new_email) { 'newbie@example.com' }
  let(:new_kc_id) { 'kc-new-id' }
  let(:actions_url) { "#{users_url}/#{new_kc_id}/execute-actions-email" }
  let(:params) { { user: { first_name: 'New', last_name: 'Bie', email: new_email, connector_id: connector_id } } }

  describe 'GET index' do
    it 'offers an "Add a User Account" button linking to the create form' do
      get users_index_path
      expect(response.body).to include(create_form_path)
    end

    it 'omits the create button when no connector can provision accounts' do
      allow_any_instance_of(::Idp::KeycloakService).to receive(:supports_user_creation?).and_return(false)
      get users_index_path
      expect(response.body).not_to include(create_form_path)
    end
  end

  describe 'GET new' do
    it 'renders the create form' do
      get create_form_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    context 'when the email is new to the IdP' do
      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
        stub_request(:post, users_url).to_return(status: 201, headers: { 'Location' => "#{users_url}/#{new_kc_id}" })
        stub_request(:put, actions_url).to_return(status: 204)
      end

      it 'creates the local user, provisions and links the IdP, sends the setup email, and redirects to edit' do
        expect { post users_index_path, params: params }.to change(user_class, :count).by(1)

        user = user_class.find_by(email: new_email)
        expect(user.user_authentication_sources.pluck(:connector_id, :connector_user_id)).to include([connector_id, new_kc_id])
        expect(user.last_connector_id).to eq(connector_id)
        expect(a_request(:post, users_url)).to have_been_made
        expect(a_request(:put, actions_url).with(body: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'].to_json)).to have_been_made
        expect(response).to redirect_to(edit_path_for(user))
        expect(flash[:notice]).to match(/setup email has been sent/)
        expect(flash[:notice]).to match(next_step_pattern)
      end
    end

    context 'when the email already exists in the IdP' do
      let(:existing_kc_id) { 'kc-existing-id' }
      let(:existing_actions_url) { "#{users_url}/#{existing_kc_id}/execute-actions-email" }

      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).
          to_return(status: 200, body: [{ id: existing_kc_id, email: new_email }].to_json)
        stub_request(:put, existing_actions_url).to_return(status: 204)
      end

      it 'links the existing remote account instead of creating a duplicate' do
        expect { post users_index_path, params: params }.to change(user_class, :count).by(1)

        user = user_class.find_by(email: new_email)
        expect(user.user_authentication_sources.pluck(:connector_user_id)).to include(existing_kc_id)
        expect(a_request(:post, users_url)).not_to have_been_made
        expect(a_request(:put, existing_actions_url)).to have_been_made
        expect(response).to redirect_to(edit_path_for(user))
      end
    end

    context 'when the setup email fails to send' do
      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
        stub_request(:post, users_url).to_return(status: 201, headers: { 'Location' => "#{users_url}/#{new_kc_id}" })
        stub_request(:put, actions_url).to_return(status: 500, body: { errorMessage: 'SMTP down' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still creates the account, pages Sentry, and warns the email did not send' do
        post users_index_path, params: params

        user = user_class.find_by(email: new_email)
        expect(user).to be_present
        expect(Sentry).to have_received(:capture_exception_with_info)
        expect(flash[:alert]).to be_present
        expect(flash[:notice]).not_to match(/setup email has been sent/)
        expect(response).to redirect_to(edit_path_for(user))
      end
    end

    context 'when the email already exists locally' do
      let!(:dup) { create(:acl_user, email: new_email) }

      it 're-renders the form and never provisions the IdP' do
        expect { post users_index_path, params: params }.not_to change(user_class, :count)

        expect(a_request(:get, users_url)).not_to have_been_made
        expect(a_request(:post, users_url)).not_to have_been_made
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the IdP rejects the account creation' do
      before do
        stub_request(:get, users_url).with(query: { email: new_email, exact: 'true' }).to_return(status: 200, body: [].to_json)
        stub_request(:post, users_url).to_return(status: 409, body: { errorMessage: 'User exists with same username' }.to_json)
      end

      it 'does not create the local user and re-renders the form' do
        expect { post users_index_path, params: params }.not_to change(user_class, :count)

        expect(response).to have_http_status(:ok)
        expect(a_request(:put, /execute-actions-email/)).not_to have_been_made
      end
    end
  end

  # JWT is on (routes mounted), but no active connector reports itself creation-capable, so
  # require_user_creation_available! sends the admin back to the index instead of the form.
  describe 'when no connector can provision accounts' do
    before do
      allow_any_instance_of(::Idp::KeycloakService).to receive(:supports_user_creation?).and_return(false)
    end

    it 'redirects GET new to the index with an unavailable alert' do
      get create_form_path

      expect(response).to redirect_to(users_index_path)
      expect(flash[:alert]).to match(/not available/i)
    end

    it 'redirects POST create to the index without creating a user' do
      expect { post users_index_path, params: params }.not_to change(user_class, :count)

      expect(response).to redirect_to(users_index_path)
      expect(flash[:alert]).to match(/not available/i)
    end
  end
end
