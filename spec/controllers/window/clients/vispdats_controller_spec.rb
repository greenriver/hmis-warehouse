require 'rails_helper'

RSpec.describe Window::Clients::VispdatsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Vispdat. As you add validations to Vispdat, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    build(:vispdat).attributes
  }
  let(:vispdat) {
    create(:vispdat)
  }
  let(:client) {
    create(:grda_warehouse_hud_client)
  }

  let(:invalid_attributes) {}

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VispdatsController. Be sure to keep this updated too.
  let(:valid_session) { }

   let(:user) { create :user }
   let(:vispdat_editor) { create :vispdat_editor }
 
   before(:each) do
     user.roles << vispdat_editor
     authenticate(user)
   end

  describe "GET #index" do
    it "assigns all vispdats as @vispdats" do
      vispdat.client = client
      vispdat.save
      get :index, client_id: vispdat.client.to_param
      expect(assigns(:vispdats)).to eq([vispdat])
    end
  end

  describe "GET #show" do
    it "assigns the requested vispdat as @vispdat" do
      vispdat.client = client
      vispdat.save
      get :show, id: vispdat.to_param, client_id: vispdat.client.to_param
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe "GET #show" do
    it "renders show" do
      vispdat.client = client
      vispdat.save
      get :show, id: vispdat.to_param, client_id: vispdat.client.to_param
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit" do
    it "assigns the requested vispdat as @vispdat" do
      vispdat.client = client
      vispdat.save
      get :edit, id: vispdat.to_param, client_id: vispdat.client.to_param
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Vispdat" do
        expect {
          post :create, client_id: client.to_param, params: {vispdat: valid_attributes}
        }.to change(GrdaWarehouse::Vispdat, :count).by(1)
      end

      it "assigns a newly created vispdat as @vispdat" do
        post :create, client_id: client.to_param, params: {vispdat: valid_attributes}
        expect(assigns(:vispdat)).to be_a(GrdaWarehouse::Vispdat)
        expect(assigns(:vispdat)).to be_persisted
      end

      it "sets the user_id to current_user" do
        post :create, client_id: client.to_param, params: {vispdat: valid_attributes}
        expect(assigns(:vispdat).user_id).to eq user.id
      end

    end

    context "with invalid params" do
      it "creates a stub vispdat as @vispdat" do
        post :create, client_id: client.to_param, params: {vispdat: invalid_attributes}
        expect(assigns(:vispdat)).to be_a(GrdaWarehouse::Vispdat)
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
