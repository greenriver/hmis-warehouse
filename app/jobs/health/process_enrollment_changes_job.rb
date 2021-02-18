###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ProcessEnrollmentChangesJob < BaseJob
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

          if disenrollment_date.present? && referral.nil?
            # This is a disenrollment, but we don't have an enrollment
            audit_actions[subscriber_id] = Health::Enrollment::DISENROLLMENT
            referral = enroll_patient(transaction)
            disenroll_patient(transaction, referral, file_date)
            disenrolled_patients += 1

          elsif disenrollment_date.present? && referral.disenrolled?
            # This is a disenrollment, and the patient is already disenrolled
            audit_actions[subscriber_id] = Health::Enrollment::DISENROLLMENT

            if Health::Enrollment.enrollment_date(transaction) > referral.enrollment_start_date
              # The audit is for an later enrollment than our current one, add it for consistency
              referral = re_enroll_patient(referral, transaction)
              disenroll_patient(transaction, referral, file_date)
              disenrolled_patients += 1
            end

          elsif disenrollment_date.present?
            # This is a missed disenrollment
            audit_actions[subscriber_id] = Health::Enrollment::DISENROLLMENT

            disenroll_patient(transaction, referral, file_date)
            disenrolled_patients += 1

          elsif referral.nil?
            # This is a missed enrollment
            audit_actions[subscriber_id] = Health::Enrollment::ENROLLMENT

            enroll_patient(transaction)
            new_patients += 1

          elsif referral.disenrolled?
            # This is a missed re-enrollment
            audit_actions[subscriber_id] = Health::Enrollment::ENROLLMENT

            if referral.re_enrollment_blackout?(file_date)
              errors << blackout_message(transaction)
            else
              re_enroll_patient(referral, transaction)
              returning_patients += 1
            end
          else
            # This is just an update
            audit_actions[subscriber_id] = Health::Enrollment::CHANGE

            update_patient_referrals(referral.patient, transaction)
            updated_patients += 1
          end

        rescue Health::MedicaidIdConflict
          # The conflict prevents us from knowing the audit action
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

    def referral(transaction)
      medicaid_id = Health::Enrollment.subscriber_id(transaction)
      referral = Health::PatientReferral.current.find_by(medicaid_id: medicaid_id)
      referral.convert_to_patient if referral.present? && referral.patient.blank?
      referral
    end

    def referral_data(transaction, change_description: nil)
      data = {
        first_name: Health::Enrollment.first_name(transaction),
        last_name: Health::Enrollment.last_name(transaction),
        middle_initial: Health::Enrollment.middle_initial(transaction),
        suffix: Health::Enrollment.name_suffix(transaction),
        birthdate: Health::Enrollment.DOB(transaction),
        ssn: Health::Enrollment.SSN(transaction),
        gender: Health::Enrollment.gender(transaction),
        medicaid_id: Health::Enrollment.subscriber_id(transaction),
        enrollment_start_date: Health::Enrollment.enrollment_date(transaction),
        cp_name_official: @receiver.cp_name_official,
        cp_pid: @receiver.pid,
        cp_sl: @receiver.sl,
        record_status: 'A', # default to active
      }

      data[:change_description] = change_description if change_description.present?

      health_enrollment_aco_pid_sl = Health::Enrollment.aco_pid_sl(transaction)
      if health_enrollment_aco_pid_sl
        pid_sl = Health::AccountableCareOrganization.split_pid_sl(health_enrollment_aco_pid_sl)
        if pid_sl.present?
          data.merge!(
            aco_mco_pid: pid_sl[:pid],
            aco_mco_sl: pid_sl[:sl],
          )
        end

        aco = Health::AccountableCareOrganization.active.find_by(
          mco_pid: pid_sl[:pid],
          mco_sl: pid_sl[:sl],
        )
        if aco.present?
          data.merge!(
            aco_name: aco.name,
            accountable_care_organization_id: aco.id,
          )
        end
      end

      data
    end

    def enroll_patient(transaction)
      Health::PatientReferral.create_referral(nil, referral_data(transaction, change_description: 'Enroll patient via 834'))
    end

    def re_enroll_patient(referral, transaction)
      patient = referral.patient
      referral_data = referral_data(transaction, change_description: 'Re-enroll patient via 834')
      if referral.enrollment_start_date == referral_data[:enrollment_start_date]
        # This is a consecutive enrollment, so carry data forward
        referral_data[:agency_id] = referral.agency_id # Agency
        # CC / NCM / ACO are preserved
      else
        # the Agency will be cleared when creating a new referral
        patient.update(care_coordinator_id: nil, nurse_care_manager_id: nil) # Clear CC.NCM
        # The ACO is preserved
      end
      Health::PatientReferral.create_referral(patient, referral_data)
    end

    def disenroll_patient(transaction, referral, file_date)
      code = Health::Enrollment.disenrollment_reason_code(transaction)

      referral.update(
        record_status: 'I', # Mark disenrolled patients as inactive
        pending_disenrollment_date: Health::Enrollment.disenrollment_date(transaction) || file_date,
        stop_reason_description: disenrollment_reason_description(code),
        change_description: 'Disenroll patient via 834',
      )
    end

    def update_patient_referrals(patient, transaction)
      updates = referral_data(transaction, change_description: 'Update patient via 834')
      current_referral = patient.patient_referral
      current_referral.assign_attributes(updates)

      return unless current_referral.changed?

      updates[:agency_id] = current_referral.agency_id unless current_referral.should_clear_assignment?

      Health::PatientReferral.create_referral(patient, updates)
    end

    def disenrollment_reason_description(code)
      @disenrollment_reasons ||= Health::DisenrollmentReason.pluck(:reason_code, :reason_description).to_h
      @disenrollment_reasons[code]
    end
  end
end
