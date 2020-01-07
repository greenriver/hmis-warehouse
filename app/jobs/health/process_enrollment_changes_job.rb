###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class ProcessEnrollmentChangesJob < ApplicationJob
    def perform(enrollment_id)
      enrollment = Health::Enrollment.find(enrollment_id)

      begin
        # counters
        new_patients = 0
        returning_patients = 0
        disenrolled_patients = 0

        enrollment.enrollments.each do |transaction|
          medicaid_id = Health::Enrollment.subscriber_id(transaction)
          referral = Health::PatientReferral.find_by(medicaid_id: medicaid_id)
          if referral.present?
            if referral.disenrollment_date.present? || referral.pending_disenrollment_date.present?
              re_enroll_patient(transaction, referral)
              returning_patients += 1
            end
            update_patient(transaction, referral)
          else
            enroll_patient(transaction)
            new_patients += 1
          end
        end

        enrollment.disenrollments.each do |transaction|
          medicaid_id = Health::Enrollment.subscriber_id(transaction)
          referral = Health::PatientReferral.find_by(medicaid_id: medicaid_id)
          if referral.present?
            disenroll_patient(transaction, referral)
            disenrolled_patients += 1
          end
        end

        enrollment.update(
          new_patients: new_patients,
          returning_patients: returning_patients,
          disenrolled_patients: disenrolled_patients,
          status: 'complete',
        )
      rescue e
        enrollment.update(status: e)
      end
    end

    def enroll_patient(transaction)
      referral = Health::PatientReferral.new
      update_patient(transaction, referral)
    end

    def re_enroll_patient(_transaction, referral)
      referral.update(
        disenrollment_date: nil,
        pending_disenrollment_date: nil,
      )
      # TODO: any other work to re-enroll
    end

    def disenroll_patient(transaction, referral)
      referral.update(pending_disenrollment_date: Health::Enrollment.disenrollment_date(transaction))
    end

    def update_patient(transaction, referral)
      pid_sl = Health::AccountableCareOrganization.split_pid_sl(Health::Enrollment.aco_pid_sl(transaction))
      aco = Health::AccountableCareOrganization.find_by(
        mco_pid: pid_sl[:pid],
        mco_sl: pid_sl[:sl],
      )

      referral.update(
        first_name: Health::Enrollment.first_name(transaction),
        last_name: Health::Enrollment.last_name(transaction),
        birthdate: Health::Enrollment.DOB(transaction),
        ssn: Health::Enrollment.SSN(transaction),
        medicaid_id: Health::Enrollment.subscriber_id(transaction),
        enrollment_start_date: Health::Enrollment.enrollment_date(transaction),
        aco: aco,
      )
    end
  end
end
