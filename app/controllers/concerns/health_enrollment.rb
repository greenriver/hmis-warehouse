###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthEnrollment
  extend ActiveSupport::Concern

  included do
    attr_accessor :receiver

    def referral(transaction)
      medicaid_id = Health::Enrollment.subscriber_id(transaction)
      referral = Health::PatientReferral.current.find_by(medicaid_id: medicaid_id)
      referral.convert_to_patient if referral.present? && referral.patient.blank?
      referral
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
        cp_name_official: receiver.cp_name_official,
        cp_pid: receiver.pid,
        cp_sl: receiver.sl,
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

    def disenroll_patient(transaction, referral, file_date)
      return if referral.removal_acknowledged?

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
