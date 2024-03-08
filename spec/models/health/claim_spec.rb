require 'rails_helper'

RSpec.describe Health::Claim, type: :model do
  let!(:sender) { create(:sender) }
  let!(:patient) { create(:patient) }
  let!(:ssm) { create(:ssm, patient_id: patient.id, housing_score: 1) }
  let!(:qa1) { create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.current, force_payable: true) }
  # QA2 is generated, so we retrieve it
  # 2024-03-06 do not produce an SDoH QA if there is not previous housing status. so qa2 is nil
  let!(:qa2) { Health::QualifyingActivity.find_by(date_of_activity: Date.current, activity: :sdoh_positive) }
  let!(:qa3) { create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.yesterday, force_payable: true) }
  let!(:qa4) { create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.yesterday, activity: :sdoh_positive, force_payable: true) }
  let!(:qa5) { create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.yesterday, mode_of_contact: :phone_call, force_payable: true) }
  let!(:qa6) do
    create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.yesterday, mode_of_contact: :phone_call,
                                 reached_client: :collateral, reached_client_collateral_contact: 'who', force_payable: true)
  end
  let!(:claim) { create :health_claim }

  before(:each) do
    claim.qualifying_activities = Health::QualifyingActivity.all
  end

  it 'smoke test' do
    claim.build_claims_file
    claim.convert_claims_to_text
  end
end
