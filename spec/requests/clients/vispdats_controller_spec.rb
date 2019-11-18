require 'rails_helper'

RSpec.describe Clients::VispdatsController, type: :request do
  # This should return the minimal set of attributes required to create a valid
  # Vispdat. As you add validations to Vispdat, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    build(:vispdat).attributes
  end
  let(:vispdat) do
    create(:vispdat)
  end
  let(:client) do
    create(:grda_warehouse_hud_client)
  end

  let(:invalid_attributes) {}

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VispdatsController. Be sure to keep this updated too.
  let(:valid_session) {}

  let(:user) { create :user }
  let(:vispdat_editor) { create :vispdat_editor }

  before(:each) do
    user.roles << vispdat_editor
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns all vispdats as @vispdats' do
      vispdat.client = client
      vispdat.save
      get client_vispdats_path(vispdat.client)
      expect(assigns(:vispdats)).to eq([vispdat])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested vispdat as @vispdat' do
      vispdat.client = client
      vispdat.save
      get client_vispdat_path(vispdat.client, vispdat)
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe 'GET #show' do
    it 'renders show' do
      vispdat.client = client
      vispdat.save
      get client_vispdat_path(vispdat.client, vispdat)
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested vispdat as @vispdat' do
      vispdat.client = client
      vispdat.save
      get edit_client_vispdat_path(vispdat.client, vispdat)
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Vispdat' do
        expect do
          post client_vispdats_path(client), params: { vispdat: valid_attributes, type: 'GrdaWarehouse::Vispdat::Individual' }
        end.to change(GrdaWarehouse::Vispdat::Individual, :count).by(1)
      end

      it 'assigns a newly created vispdat as @vispdat' do
        post client_vispdats_path(client), params: { vispdat: valid_attributes }
        expect(assigns(:vispdat)).to be_a(GrdaWarehouse::Vispdat::Individual)
        expect(assigns(:vispdat)).to be_persisted
      end

      it 'sets the user_id to current_user' do
        post client_vispdats_path(client), params: { vispdat: valid_attributes }
        expect(assigns(:vispdat).user_id).to eq user.id
      end
    end

    context 'with invalid params' do
      it 'creates a stub vispdat as @vispdat' do
        post client_vispdats_path(client), params: { vispdat: invalid_attributes }
        expect(assigns(:vispdat)).to be_a(GrdaWarehouse::Vispdat::Individual)
      end
    end
  end
end
