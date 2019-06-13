require 'rails_helper'

RSpec.describe Health::Patient, type: :model do
  let(:patient_01) { build :patient, client_id: 999 }
  let(:patient_02) { build :patient, client_id: 999 }
  let(:patient_03) { build :patient, client_id: 999, deleted_at: Time.now }

  describe 'uniqueness constraints' do
    it 'forbid two patients with same client id' do
      patient_01.save!
      expect { patient_02.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allow two patients with the same client id, if one is soft deleted' do
      patient_03.save!
      patient_01.save!

      expect(Health::Patient.all).to include patient_01
    end

    it 'allow two patients with the same client id, if one is soft deleted, but not adding a third' do
      patient_03.save!
      patient_01.save!

      expect { patient_02.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
