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

  it 'sends only the relevant patients to a coordinator' do
    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    coordinator_a_email = ActionMailer::Base.deliveries.detect { |email| email.header.encoded.include? coordinator_a.email }
    expect(coordinator_a_email.body.encoded).not_to include(*coordinator_a_aco_patients.map { |p| p.id.to_s })
    expect(coordinator_a_email.body.encoded).to include(*coordinator_a_standard_patients.map { |p| p.id.to_s })
    expect(coordinator_a_email.body.encoded).to include(*coordinator_a_uncovered_patients.map { |p| p.id.to_s })

    other_coordinators_patients = coordinator_b_aco_patients +
                                  coordinator_b_standard_patients +
                                  coordinator_b_uncovered_patients +
                                  coordinator_c_aco_patients
    expect(coordinator_a_email.body.encoded).not_to include(*other_coordinators_patients.map { |p| p.id.to_s })
  end

  it 'will not send a coordinator an email if all their patients have been flagged already' do
    expect(ActionMailer::Base.deliveries.size).to eq 0

    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 2

    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 2
  end
end
