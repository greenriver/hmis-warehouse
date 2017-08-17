require 'rails_helper'

RSpec.describe Clients::VispdatsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Vispdat. As you add validations to Vispdat, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {}

  let(:invalid_attributes) {}

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VispdatsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    skip "assigns all vispdats as @vispdats" do
      vispdat = Vispdat.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(assigns(:vispdats)).to eq([vispdat])
    end
  end

  describe "GET #show" do
    skip "assigns the requested vispdat as @vispdat" do
      vispdat = Vispdat.create! valid_attributes
      get :show, params: {id: vispdat.to_param}, session: valid_session
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe "GET #new" do
    skip "assigns a new vispdat as @vispdat" do
      get :new, params: {}, session: valid_session
      expect(assigns(:vispdat)).to be_a_new(Vispdat)
    end
  end

  describe "GET #edit" do
    skip "assigns the requested vispdat as @vispdat" do
      vispdat = Vispdat.create! valid_attributes
      get :edit, params: {id: vispdat.to_param}, session: valid_session
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      skip "creates a new Vispdat" do
        expect {
          post :create, params: {vispdat: valid_attributes}, session: valid_session
        }.to change(Vispdat, :count).by(1)
      end

      skip "assigns a newly created vispdat as @vispdat" do
        post :create, params: {vispdat: valid_attributes}, session: valid_session
        expect(assigns(:vispdat)).to be_a(Vispdat)
        expect(assigns(:vispdat)).to be_persisted
      end

      skip "redirects to the created vispdat" do
        post :create, params: {vispdat: valid_attributes}, session: valid_session
        expect(response).to redirect_to(Vispdat.last)
      end
    end

    context "with invalid params" do
      skip "assigns a newly created but unsaved vispdat as @vispdat" do
        post :create, params: {vispdat: invalid_attributes}, session: valid_session
        expect(assigns(:vispdat)).to be_a_new(Vispdat)
      end

      skip "re-renders the 'new' template" do
        post :create, params: {vispdat: invalid_attributes}, session: valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      skip "updates the requested vispdat" do
        vispdat = Vispdat.create! valid_attributes
        put :update, params: {id: vispdat.to_param, vispdat: new_attributes}, session: valid_session
        vispdat.reload
        skip("Add assertions for updated state")
      end

      skip "assigns the requested vispdat as @vispdat" do
        vispdat = Vispdat.create! valid_attributes
        put :update, params: {id: vispdat.to_param, vispdat: valid_attributes}, session: valid_session
        expect(assigns(:vispdat)).to eq(vispdat)
      end

      skip "redirects to the vispdat" do
        vispdat = Vispdat.create! valid_attributes
        put :update, params: {id: vispdat.to_param, vispdat: valid_attributes}, session: valid_session
        expect(response).to redirect_to(vispdat)
      end
    end

    context "with invalid params" do
      skip "assigns the vispdat as @vispdat" do
        vispdat = Vispdat.create! valid_attributes
        put :update, params: {id: vispdat.to_param, vispdat: invalid_attributes}, session: valid_session
        expect(assigns(:vispdat)).to eq(vispdat)
      end

      skip "re-renders the 'edit' template" do
        vispdat = Vispdat.create! valid_attributes
        put :update, params: {id: vispdat.to_param, vispdat: invalid_attributes}, session: valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    skip "destroys the requested vispdat" do
      vispdat = Vispdat.create! valid_attributes
      expect {
        delete :destroy, params: {id: vispdat.to_param}, session: valid_session
      }.to change(Vispdat, :count).by(-1)
    end

    skip "redirects to the vispdats list" do
      vispdat = Vispdat.create! valid_attributes
      delete :destroy, params: {id: vispdat.to_param}, session: valid_session
      expect(response).to redirect_to(vispdats_url)
    end
  end

end
