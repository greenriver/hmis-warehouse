module Health
  class FlagIneligiblePatientsJob < ActiveJob::Base
    def perform(inquiry_id)
      inquiry = Health::EligibilityInquiry.find(inquiry_id)
      response = inquiry.eligibility_response

      if response
        # Update the last check date
        Health::Patient.where(medicaid_id: response.subscriber_ids).find_each do |patient|
          patient.update(coverage_inquiry_date: inquiry.service_date)
        end

        # Clear the eligibility notification flag on managed patients, so that if they lose eligibility again,
        # we will re-flag them
        Health::Patient.where(medicaid_id: response.managed_care_ids).find_each do |patient|
          patient.update(eligibility_notification: nil)
        end

        # Set the eligibility level for covered patients
        Health::Patient.where(medicaid_id: response.eligible_ids).find_each do |patient|
          patient.update(coverage_level: Health::Patient.coverage_level_standard_value)
        end

        # Set the eligibility level for managed care patients
        Health::Patient.where(medicaid_id: response.managed_care_ids).find_each do |patient|
          patient.update(coverage_level: Health::Patient.coverage_level_managed_value)
        end

        # Mark ineligible patients
        Health::Patient.where(medicaid_id: response.ineligible_ids).find_each do |patient|
          patient.update(coverage_level: Health::Patient.coverage_level_none_value)
        end

        notify_care_coordinators(response)
      end
    end

    def notify_care_coordinators(response)
      groups = Health::Patient.where(medicaid_id: response.ineligible_ids).
        joins(:team_members).
        where(team_members: {type: 'Health::Team::CareCoordinator'}).
        where(eligibility_notification: nil).
        group_by{|patient| patient.team_members}

      groups.each do |coordinators, patients|
        ids = patients.map{ |patient| patient.client.id}
        coordinators.each do |coordinator|
          IneligiblePatientMailer.ineligible_patients(coordinator.email, ids).deliver_later
        end
        patients.each do |patient|
          patient.update(eligibility_notification: Time.now)
        end
      end

      groups = Health::Patient.where(medicaid_id: response.eligible_ids - response.managed_care_ids).
        joins(:team_members).
        where(team_members: {type: 'Health::Team::CareCoordinator'}).
        where(eligibility_notification: nil).
        group_by{|patient| patient.team_members}

      groups.each do |coordinators, patients|
        ids = patients.map{ |patient| patient.client.id}
        coordinators.each do |coordinator|
          IneligiblePatientMailer.no_managed_care_patients(coordinator.email, ids).deliver_later
        end
        patients.each do |patient|
          patient.update(eligibility_notification: Time.now)
        end
      end
    end
  end
end