###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class ProcessEnrollmentChangesJob < ActiveJob::Base
    def perform(enrollment_id)
      enrollment = Health::Enrollment.find(enrollment_id)

      # counters
      new_patients = 0
      returning_patients = 0
      disenrolled_patients = 0

      enrollment.enrollments.each do |transaction|
        medicaid_id = enrollment.subscriber_id(transaction)
        referral = Health::PatientReferral.find_by(medicaid_id: medicaid_id)
        if referral.present?
          if referral.disenrollment_date.present?
            re_enroll_patient(enrollment, referral)
            returning_patients += 1
          end
          update_patient(enrollment, referral)
        else
          enroll_patient(enrollment)
          new_patients += 1
        end
      end

      enrollment.disenrollments.each do |transaction|
        medicaid_id = enrollment.subscriber_id(transaction)
        referral = Health::PatientReferral.find_by(medicaid_id: medicaid_id)
        if referral.present?
          disenroll_patient(enrollment, referral)
          disenrolled_patients += 1
        end
      end
      
      enrollment.update(new_patients: new_patients,
        returning_patients: returning_patients,
        disenrolled_patients: disenrolled_patients)
    end

    def enroll_patient(enrollment)

    end

    def re_enroll_patient(enrollment, referral)

    end

    def disenroll_patient(enrollment, referral)

    end

    def update_patient(enrollment, referral)

    end
  end
end