# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Health::PatientsController, type: :controller do
  let(:user) { create(:user) }
  let(:role) { create(:role, can_administer_health: true, health_role: true) }

  # Create actual patients for testing
  let!(:patient1) { create(:patient, client: create(:hud_client)) }
  let!(:patient2) { create(:patient, client: create(:hud_client)) }
  let!(:patient3) { create(:patient, client: create(:hud_client)) }

  before do
    user.health_roles << role
    user.save!
    sign_in user
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns patients' do
      get :index
      expect(assigns(:patients)).not_to be_nil
    end

    it 'paginates results' do
      get :index
      expect(assigns(:pagy)).to be_a(Pagy)
    end

    context 'with sort parameters' do
      it 'respects sort parameters' do
        get :index, params: { sort: 'patient_last_name', direction: 'desc' }

        expect(assigns(:column)).to eq(:patient_last_name)
        expect(assigns(:direction)).to eq(:desc)
      end
    end

    context 'with search query' do
      let!(:searchable_patient) { create(:patient, last_name: 'Searchable', first_name: 'Patient', pilot: true) }

      it 'finds patients by last name' do
        get :index, params: { q: 'Searchable' }

        expect(response).to be_successful
        expect(assigns(:patients)).to include(searchable_patient)
      end

      it 'finds patients by first name' do
        get :index, params: { q: 'Patient' }

        expect(response).to be_successful
        expect(assigns(:patients)).to include(searchable_patient)
      end

      it 'finds patients by full name with space' do
        get :index, params: { q: 'Patient Searchable' }

        expect(response).to be_successful
        expect(assigns(:patients)).to include(searchable_patient)
      end

      it 'does not find patients with non-matching query' do
        get :index, params: { q: 'NonExistentName' }

        expect(response).to be_successful
        expect(assigns(:patients)).not_to include(searchable_patient)
      end
    end
  end
end
