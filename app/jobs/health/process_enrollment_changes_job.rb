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

      pidsls = Health::Cp.all.map { |cp| cp.pid + cp.sl }
      receiver_id = enrollment.receiver_id
      unless pidsls.include?(receiver_id)
        enrollment.update(status: "Unexpected receiver ID #{receiver_id}")
        return
      end

      begin
        # counters
        new_patients = 0
        returning_patients = 0
        disenrolled_patients = 0
        updated_patients = 0

        enrollment.enrollments.each do |transaction|
          referral = referral(transaction)
          if referral.present?
            if referral.disenrolled?
              re_enroll_patient(referral, transaction)
              returning_patients += 1
            else
              updated_patients += 1
            end
            update_patient_referrals(referral.patient, transaction)
          else
            enroll_patient(transaction)
            new_patients += 1
          end
        end

        enrollment.disenrollments.each do |transaction|
          referral = referral(transaction)
          if referral.present?
            disenroll_patient(transaction, referral)
            disenrolled_patients += 1
          end
        end

        enrollment.changes.each do |transaction|
          referral = referral(transaction)
          if referral.present?
            update_patient_referrals(referral.patient, transaction)
            updated_patients += 1
          end
        end

        enrollment.audits.each do |transaction|
          referral = referral(transaction)
          disenrollment_date = Health::Enrollment.disenrollment_date(transaction)

          if disenrollment_date.present?
            next if referral.nil? # This is a disenrollment, but we never enrolled this patient
            next if referral.disenrolled? # This is a disenrollment, and the patient is already disenrolled

            # This is a missed disenrollment
            disenroll_patient(transaction, referral)
            disenrolled_patients += 1

          elsif referral.nil?
            # This is a missed enrollment
            enroll_patient(transaction)
            new_patients += 1

          elsif referral.disenrolled?
            # This is a missed re-enrollment

            re_enroll_patient(referral, transaction)
            update_patient_referrals(referral.patient, transaction)
            returning_patients += 1
          else
            # This is just an update
            update_patient_referrals(referral.patient, transaction)
            updated_patients += 1
          end
        end

        enrollment.update(
          new_patients: new_patients,
          returning_patients: returning_patients,
          disenrolled_patients: disenrolled_patients,
          updated_patients: updated_patients,
          status: 'complete',
        )

        Health::Tasks::CalculateValidUnpayableQas.new.run!
      rescue Exception => e
        enrollment.update(status: e)
      end
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
        birthdate: Health::Enrollment.DOB(transaction),
        ssn: Health::Enrollment.SSN(transaction),
        gender: Health::Enrollment.gender(transaction),
        medicaid_id: Health::Enrollment.subscriber_id(transaction),
        enrollment_start_date: Health::Enrollment.enrollment_date(transaction),
      }

      health_enrollment_aco_pid_sl = Health::Enrollment.aco_pid_sl(transaction)
      if health_enrollment_aco_pid_sl
        pid_sl = Health::AccountableCareOrganization.split_pid_sl(health_enrollment_aco_pid_sl)
        aco = Health::AccountableCareOrganization.active.find_by(
          mco_pid: pid_sl[:pid],
          mco_sl: pid_sl[:sl],
        )
        data[:aco] = aco if aco.present?
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

    def disenroll_patient(transaction, referral)
      code = Health::Enrollment.disenrollment_reason_code(transaction)

      referral.update(
        pending_disenrollment_date: Health::Enrollment.disenrollment_date(transaction),
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
