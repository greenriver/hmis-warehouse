###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HRSN homeless changes', type: :model do
  let!(:patient) { create(:patient) }
  # Give patient a housing status history
  let!(:ssm) { create(:ssm, patient_id: patient.id, housing_score: 0, completed_at: Date.yesterday) }
  # Make patient engaged
  let!(:careplan) { create(:careplan, patient_id: patient.id, careplan_sent_on: Date.current) }
  let!(:pctp_careplan) { create(:pctp_careplan, instrument: careplan, patient_id: patient.id) }
  let!(:ssm2) { create(:ssm, patient_id: patient.id, housing_score: 1) }
  let!(:ssm3) { create(:ssm, patient_id: patient.id, housing_score: 2) }

  it 'only create one qa' do
    expect(Health::QualifyingActivity.count).to eq 1
  end
end
