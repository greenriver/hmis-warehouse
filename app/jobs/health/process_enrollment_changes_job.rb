###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ProcessEnrollmentChangesJob < BaseJob
    include HealthEnrollment

    queue_as :long_running

    def perform(enrollment_id)
      enrollment = Health::Enrollment.find(enrollment_id)

      receiver_id = enrollment.receiver_id
      @receiver = Health::Cp.find_by(
        pid: receiver_id[0...-1],
        sl: receiver_id.last,
      )
      unless @receiver.present?
        enrollment.update(status: "Unexpected receiver ID #{receiver_id}")
        return
      end

      begin
        # counters
        new_patients = 0
        returning_patients = 0
        disenrolled_patients = 0
        updated_patients = 0
        errors = []

        file_date = enrollment.file_date

        enrollment.enrollments.each do |transaction|
          referral = referral(transaction)
          if referral.present?
            if referral.disenrolled?
              if referral.re_enrollment_blackout?(file_date)
                errors << blackout_message(transaction)
              else
                begin
                  re_enroll_patient(referral, transaction)
                  returning_patients += 1
                rescue Health::MedicaidIdConflict # rubocop:disable Metrics/BlockNesting
                  errors << conflict_message(transaction)
                end
              end
            else
              begin
                update_patient_referrals(referral.patient, transaction)
                updated_patients += 1
              rescue Health::MedicaidIdConflict
                errors << conflict_message(transaction)
              end
            end
          else
            begin
              enroll_patient(transaction)
              new_patients += 1
            rescue Health::MedicaidIdConflict
              errors << conflict_message(transaction)
            end
          end
        end

        enrollment.disenrollments.each do |transaction|
          referral = referral(transaction)
          if referral.present?
            disenroll_patient(transaction, referral, file_date)
            disenrolled_patients += 1
          end
        end

        enrollment.changes.each do |transaction|
          referral = referral(transaction)
          next unless referral.present?
          next if referral.disenrolled? # Ignore changes if the patient is disenrolled

          update_patient_referrals(referral.patient, transaction)
          updated_patients += 1
        rescue Health::MedicaidIdConflict
          errors << conflict_message(transaction)
        end

        audit_actions = {}
        enrollment.audits.each do |transaction|
          referral = referral(transaction)
          disenrollment_date = Health::Enrollment.disenrollment_date(transaction)
          subscriber_id = Health::Enrollment.subscriber_id(transaction)

          if disenrollment_date.present?
            next if referral.nil? # This is a disenrollment, but we never enrolled this patient
            next if referral.disenrolled? # This is a disenrollment, and the patient is already disenrolled

            # This is a missed disenrollment
            audit_actions[subscriber_id] = Health::Enrollment::DISENROLLMENT
            disenroll_patient(transaction, referral, file_date)
            disenrolled_patients += 1

          elsif referral.nil?
            # This is a missed enrollment
            audit_actions[subscriber_id] = Health::Enrollment::ENROLLMENT
            begin
              enroll_patient(transaction)
              new_patients += 1
            rescue Health::MedicaidIdConflict
              errors << conflict_message(transaction)
            end

          elsif referral.disenrolled?
            # This is a missed re-enrollment
            audit_actions[subscriber_id] = Health::Enrollment::ENROLLMENT
            if referral.re_enrollment_blackout?(file_date)
              errors << blackout_message(transaction)
            else
              begin
                re_enroll_patient(referral, transaction)
                returning_patients += 1
              rescue Health::MedicaidIdConflict
                errors << conflict_message(transaction)
              end
            end
          else
            # This is just an update
            audit_actions[subscriber_id] = Health::Enrollment::CHANGE
            begin
              update_patient_referrals(referral.patient, transaction)
              updated_patients += 1
            rescue Health::MedicaidIdConflict
              errors << conflict_message(transaction)
            end
          end

        rescue Health::MedicaidIdConflict
          # The conflict prevents uus from knowing the audit action
          errors << conflict_message(transaction)
        end

        enrollment.update(
          new_patients: new_patients,
          returning_patients: returning_patients,
          disenrolled_patients: disenrolled_patients,
          updated_patients: updated_patients,
          processing_errors: errors,
          audit_actions: audit_actions,
          status: 'complete',
        )

        Health::Tasks::CalculateValidUnpayableQas.new.run!
      rescue Exception => e
        enrollment.update(
          processing_errors: errors,
          status: e,
        )
      end
    end

    def conflict_message(transaction)
      medicaid_id = Health::Enrollment.subscriber_id(transaction)
      "ID #{medicaid_id} in 834 conflicts with existing patient records"
    end

    def blackout_message(transaction)
      medicaid_id = Health::Enrollment.subscriber_id(transaction)
      "ID #{medicaid_id} not re-enrolled, in re-enrollment blackout period"
    end
  end
end
