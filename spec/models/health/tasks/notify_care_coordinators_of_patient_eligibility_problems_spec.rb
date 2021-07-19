require 'rails_helper'

RSpec.describe Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems, type: :model do
  let!(:sender) { create :sender }

  let(:user) { create :user }
  let(:coordinator_a) { create :user }
  let(:coordinator_b) { create :user }
  let(:coordinator_c) { create :user }
  let(:coordinator_d) { create :user }

  # "user" has no patients

  let!(:coordinator_a_aco_patients) { create_list :patient, 5, coverage_level: 'managed', care_coordinator_id: coordinator_a.id }
  let!(:coordinator_a_standard_patients) { create_list :patient, 5, coverage_level: 'standard', care_coordinator_id: coordinator_a.id }
  let!(:coordinator_a_uncovered_patients) { create_list :patient, 5, coverage_level: 'none', care_coordinator_id: coordinator_a.id }

  let!(:coordinator_b_aco_patients) { create_list :patient, 5, coverage_level: 'managed', care_coordinator_id: coordinator_b.id }
  let!(:coordinator_b_standard_patients) { create_list :patient, 5, coverage_level: 'standard', care_coordinator_id: coordinator_b.id }
  let!(:coordinator_b_uncovered_patients) { create_list :patient, 5, coverage_level: 'none', care_coordinator_id: coordinator_b.id }

  # "coordinator_c" has patients, but no notifications
  let!(:coordinator_c_aco_patients) { create_list :patient, 5, coverage_level: 'managed', care_coordinator_id: coordinator_c.id }

  # "coordinator_d" has only one kind of notifications
  let!(:coordinator_d_uncovered_patients) { create_list :patient, 5, coverage_level: 'none', care_coordinator_id: coordinator_d.id }

  before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  after(:all) do
    # The enrollments and project sequences seem to drift.
    # This ensures we'll have one to test
    FactoryBot.reload
  end

  it 'sends each coordinator at most one email' do
    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 3
  end

  it 'sends only the relevant patients to a coordinator' do
    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    coordinator_a_email = ActionMailer::Base.deliveries.detect { |email| email.header.encoded.include? coordinator_a.email }
    expect(coordinator_a_email.body.encoded).not_to include(*patient_links(coordinator_a_aco_patients))
    expect(coordinator_a_email.body.encoded).to include(*patient_links(coordinator_a_standard_patients))
    expect(coordinator_a_email.body.encoded).to include(*patient_links(coordinator_a_uncovered_patients))

    other_coordinators_patients = coordinator_b_aco_patients +
                                  coordinator_b_standard_patients +
                                  coordinator_b_uncovered_patients +
                                  coordinator_c_aco_patients
    expect(coordinator_a_email.body.encoded).not_to include(*patient_links(other_coordinators_patients))
  end

  it 'will not send a coordinator an email if all their patients have been flagged already' do
    expect(ActionMailer::Base.deliveries.size).to eq 0

    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 3

    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!

    expect(ActionMailer::Base.deliveries.size).to eq 3
  end

  def patient_links(patients)
    patients.map { |p| client_health_patient_index_path(p.client_id) }
  end
end
