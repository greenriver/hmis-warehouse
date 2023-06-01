require 'rails_helper'

RSpec.describe Health::Claim, type: :model do
  let!(:sender) { create(:sender) }
  let!(:patient) { create(:patient) }
  let!(:ssm) { create(:ssm, patient_id: patient.id, housing_score: 1) }
  let!(:qa1) { create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.current, force_payable: true) }
  let!(:qa2) { create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.current, activity: :sdoh_positive, force_payable: true) }
  let!(:claim) { create :health_claim }

  before(:each) do
    claim.qualifying_activities << qa1
    claim.qualifying_activities << qa2
  end

  it 'smoke test' do
    claim.build_claims_file
    claim.convert_claims_to_text
  end
end
