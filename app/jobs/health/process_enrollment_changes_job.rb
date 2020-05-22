###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class ProcessEnrollmentChangesJob < ApplicationJob
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
              re_enroll_patient(referral.patient, transaction)
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

          audit_date = enrollment.file_date
          is_disenrollment = disenrollment_date.beginning_of_month == audit_date.beginning_of_month

          if referral.present?
            if is_disenrollment
              if referral.disenrollment_date.blank? && referral.pending_disenrollment_date.blank?
                disenroll_patient(transaction, referral)
                disenrolled_patients += 1
              end
            else
              if referral.disenrollment_date.present? || referral.pending_disenrollment_date.present?
                re_enroll_patient(referral.patient, transaction)
                returning_patients += 1
              else
                updated_patients += 1
              end
              update_patient_referrals(referral.patient, transaction)
            end
          else
            unless is_disenrollment
              enroll_patient(transaction)
              new_patients += 1
            end
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
      Health::PatientReferral.current.find_by(medicaid_id: medicaid_id)
    end

    def enroll_patient(transaction)
      update_patient_referrals(nil, transaction)
    end

    def re_enroll_patient(patient, transaction)
      update_patient_referrals(patient, transaction)
    end

    def disenroll_patient(transaction, referral)
      code = Health::Enrollment.disenrollment_reason_code(transaction)

      referral.update(
        pending_disenrollment_date: Health::Enrollment.disenrollment_date(transaction),
        stop_reason_description: disenrollment_reason_description(code),
      )
    end

    def update_patient_referrals(patient, transaction)
      updates = {
        first_name: Health::Enrollment.first_name(transaction),
        last_name: Health::Enrollment.last_name(transaction),
        birthdate: Health::Enrollment.DOB(transaction),
        ssn: Health::Enrollment.SSN(transaction),
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
        updates[:aco] = aco if aco.present?
      end

      if patient.present?
        current_referral = patient.patient_referral
        current_referral.assign_attributes(updates)
        return unless current_referral.changed?

        if update[:enrollment_start_date] != current_referral.enrollment_start_date
          updates[:agency_id] = current_referral.agency_id
          Health::PatientReferral.create_referral(patient, updates)
        else
          current_referral.save
        end
      else
        Health::PatientReferral.create_referral(patient, updates)
      end
    end

    def disenrollment_reason_description(code)
      @disenrollment_reasons ||= Health::DisenrollmentReason.pluck(:reason_code, :reason_description).to_h
      @disenrollment_reasons[code]
    end
  end
end
