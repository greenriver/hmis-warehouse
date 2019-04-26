require 'rails_helper'

RSpec.describe Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems, type: :model do
  let!(:sender) { create :sender }

  let(:user) { create :user }
  let(:coordinator_a) { create :user }
  let(:coordinator_b) { create :user }
  let(:coordinator_c) { create :user }

  # "user" has no patients

  let!(:coordinator_a_aco_patients) { create_list :patient, 5, coverage_level: 'managed', care_coordinator_id: coordinator_a.id }
  let!(:coordinator_a_standard_patients) { create_list :patient, 5, coverage_level: 'standard', care_coordinator_id: coordinator_a.id }
  let!(:coordinator_a_uncovered_patients) { create_list :patient, 5, coverage_level: 'none', care_coordinator_id: coordinator_a.id }

  let!(:coordinator_b_aco_patients) { create_list :patient, 5, coverage_level: 'managed', care_coordinator_id: coordinator_b.id }
  let!(:coordinator_b_standard_patients) { create_list :patient, 5, coverage_level: 'standard', care_coordinator_id: coordinator_b.id }
  let!(:coordinator_b_uncovered_patients) { create_list :patient, 5, coverage_level: 'none', care_coordinator_id: coordinator_b.id }

  let!(:coordinator_c_aco_patients) { create_list :patient, 5, coverage_level: 'managed', care_coordinator_id: coordinator_c.id }

  before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  it 'sends each coordinator at most one email' do
    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 2
  end

  it 'will not send a coordinator an email if all their patients have been flagged already' do
    expect(ActionMailer::Base.deliveries.size).to eq 0

    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 2

    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 2
  end
end
