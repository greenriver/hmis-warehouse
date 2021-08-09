require 'rails_helper'

RSpec.describe 'careplans date concern', type: :model do
  let(:test_class) { Struct.new(:patient_ids) { include Health::CareplanDates, ArelHelper } }
  let(:patient) { create :patient }
  let(:careplan_dates) { test_class.new(patient.id) }

  describe 'patient has one submitted careplan' do
    let!(:careplan) { create :careplan, patient_id: patient.id, provider_signature_requested_at: Date.yesterday }

    it 'has has submission, but not signature dates' do
      expect(careplan_dates.send(:care_plan_sent_to_provider_date, patient.id)).to eq(Date.yesterday)
      expect(careplan_dates.send(:care_plan_provider_signed_date, patient.id)).to eq(nil)
    end
  end

  describe 'patient has one signed careplan' do
    let!(:careplan) { create :careplan, patient_id: patient.id, provider_signature_requested_at: Date.yesterday, provider_signed_on: Date.today }

    it 'has has submission, and signature dates' do
      expect(careplan_dates.send(:care_plan_sent_to_provider_date, patient.id)).to eq(Date.yesterday)
      expect(careplan_dates.send(:care_plan_provider_signed_date, patient.id)).to eq(Date.today)
    end
  end

  describe 'patient has a signed careplan, and a newer submitted one' do
    let!(:careplan) { create :careplan, patient_id: patient.id, provider_signature_requested_at: Date.yesterday, provider_signed_on: Date.today }
    let!(:careplan2) { create :careplan, patient_id: patient.id, provider_signature_requested_at: Date.today }

    it 'has has old submission, and signature dates' do
      expect(careplan_dates.send(:care_plan_sent_to_provider_date, patient.id)).to eq(Date.yesterday)
      expect(careplan_dates.send(:care_plan_provider_signed_date, patient.id)).to eq(Date.today)
    end
  end

  describe 'patient has a newer signed careplan' do
    let!(:careplan) { create :careplan, patient_id: patient.id, provider_signature_requested_at: Date.yesterday, provider_signed_on: Date.today }
    let!(:careplan2) { create :careplan, patient_id: patient.id, provider_signature_requested_at: Date.today, provider_signed_on: Date.tomorrow }

    it 'has has new submission, and signature dates' do
      expect(careplan_dates.send(:care_plan_sent_to_provider_date, patient.id)).to eq(Date.today)
      expect(careplan_dates.send(:care_plan_provider_signed_date, patient.id)).to eq(Date.tomorrow)
    end
  end
end
