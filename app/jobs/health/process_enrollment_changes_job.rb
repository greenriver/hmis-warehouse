###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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

        enrollment.audits.each do |transaction|
          referral = referral(transaction)
          disenrollment_date = Health::Enrollment.disenrollment_date(transaction)

          if disenrollment_date.present?
            next if referral.nil? # This is a disenrollment, but we never enrolled this patient
            next if referral.disenrolled? # This is a disenrollment, and the patient is already disenrolled

            # This is a missed disenrollment
            disenroll_patient(transaction, referral, file_date)
            disenrolled_patients += 1

          elsif referral.nil?
            # This is a missed enrollment
            begin
              enroll_patient(transaction)
              new_patients += 1
            rescue Health::MedicaidIdConflict
              errors << conflict_message(transaction)
            end

          elsif referral.disenrolled?
            # This is a missed re-enrollment
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
            begin
              update_patient_referrals(referral.patient, transaction)
              updated_patients += 1
            rescue Health::MedicaidIdConflict
              errors << conflict_message(transaction)
            end
          end
        end

        enrollment.update(
          new_patients: new_patients,
          returning_patients: returning_patients,
          disenrolled_patients: disenrolled_patients,
          updated_patients: updated_patients,
          processing_errors: errors,
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

    def referral_data(transaction)
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
      Health::PatientReferral.create_referral(nil, referral_data(transaction))
    end

    def re_enroll_patient(referral, transaction)
      patient = referral.patient
      referral_data = referral_data(transaction)
      referral_data[:agency_id] = referral.agency_id unless referral.enrollment_start_date != referral_data[:enrollment_start_date]
      Health::PatientReferral.create_referral(patient, referral_data)
    end

    def disenroll_patient(transaction, referral, file_date)
      code = Health::Enrollment.disenrollment_reason_code(transaction)

      referral.update(
        record_status: 'I', # Mark disenrolled patients as inactive
        pending_disenrollment_date: Health::Enrollment.disenrollment_date(transaction) || file_date,
        stop_reason_description: disenrollment_reason_description(code),
      )
    end

    def update_patient_referrals(patient, transaction)
      updates = referral_data(transaction)
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
