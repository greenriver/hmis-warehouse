###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class MemberStatusReport < HealthBase
    include ArelHelper
    include Health::CareplanDates

    acts_as_paranoid

    phi_attr :id, Phi::SmallPopulation

    has_many :member_status_report_patients
    belongs_to :user, optional: true

    scope :visible_by?, ->(user) do
      if user.can_view_member_health_reports? || user.can_view_aggregate_health? || user.can_administer_health?
        all
      else
        none
      end
    end

    def run!
      start_report
      sender_cp = Health::Cp.sender.first
      patient_referrals.each do |pr|
        patient = pr.patient

        most_recent_qualifying_activity = patient&.qualifying_activities&.during_current_enrollment&.direct_contact&.order(date_of_activity: :desc)&.limit(1)&.first
        # Any qa before the end of the report range?
        qa_activity_dates = patient&.qualifying_activities&.during_current_enrollment&.where(hqa_t[:date_of_activity].lteq(report_range.end))&.pluck(:date_of_activity)&.uniq || []

        next unless patient_enrolled_during_report?(patient)

        # Get the most recent modification date based on QA dates and referral date
        patient_updated_at = (qa_activity_dates + [pr.enrollment_start_date]).compact.max

        aco_mco_name = pr.aco&.name || pr.aco_name
        aco_mco_pid = pr.aco&.mco_pid || pr.aco_mco_pid
        aco_mco_sl = pr.aco&.mco_sl || pr.aco_mco_sl

        attributes = {
          medicaid_id: pr.medicaid_id,
          member_first_name: pr.first_name,
          member_last_name: pr.last_name,
          member_middle_initial: pr.middle_initial&.first,
          member_suffix: pr.suffix,
          member_date_of_birth: pr.birthdate,
          member_sex: pr.gender,
          aco_mco_name: aco_mco_name,
          aco_mco_pid: aco_mco_pid,
          aco_mco_sl: aco_mco_sl,
          cp_name_official: pr.cp_name_official,
          cp_pid: pr.cp_pid,
          cp_sl: pr.cp_sl,
          cp_outreach_status: pr.outreach_status,
          cp_last_contact_date: most_recent_qualifying_activity&.date_of_activity,
          cp_last_contact_face: client_recent_face_to_face(most_recent_qualifying_activity),
          cp_contact_face: any_face_to_face_for_patient_in_range(patient),
          cp_participation_form_date: patient&.participation_forms&.maximum(:signature_on),
          cp_care_plan_sent_pcp_date: care_plan_sent_to_provider_date(patient&.id),
          cp_care_plan_returned_pcp_date: care_plan_provider_signed_date(patient&.id),
          key_contact_name_first: sender_cp.key_contact_first_name,
          key_contact_name_last: sender_cp.key_contact_last_name,
          key_contact_phone: sender_cp.key_contact_phone&.gsub(/\D/, '')&.try(:[], 0, 10),
          key_contact_email: sender_cp.key_contact_email,
          care_coordinator_first_name: patient&.care_coordinator&.first_name,
          care_coordinator_last_name: patient&.care_coordinator&.last_name,
          care_coordinator_phone: patient&.care_coordinator&.phone&.gsub(/\D/, '')&.try(:[], 0, 10),
          care_coordinator_email: patient&.care_coordinator&.email,
          # report_start_date: report_start_date&.strftime('%Y%M%d'),
          # report_end_date: report_end_date&.strftime('%Y%M%d'),
          record_status: pr.record_status,
          record_update_date: patient_updated_at.to_date,
          export_date: effective_date,
        }

        next if receiver.present? && attributes[:aco_mco_name] != receiver

        member_status_report_patients.create!(attributes)
      end
      complete_report
    end

    private def patient_enrolled_during_report?(patient)
      return false unless patient.present?

      @patients_enrolled_during_report ||= Health::Patient.active_between(report_range.first, report_range.last).pluck(:id)
      @patients_enrolled_during_report.include?(patient.id)
    end

    def self.spreadsheet_columns
      {
        medicaid_id: 'Medicaid_ID',
        member_last_name: 'Member_Name_Last',
        member_first_name: 'Member_Name_First',
        member_middle_initial: 'Member_Middle_Initial',
        member_suffix: 'Member_Suffix',
        member_date_of_birth: 'Member_Date_of_Birth',
        member_sex: 'Member_Sex',
        aco_mco_name: 'ACO_MCO_Name',
        aco_mco_pid: 'ACO_MCO_PID',
        aco_mco_sl: 'ACO_MCO_SL',
        cp_name_official: 'CP_Name_Official',
        cp_pid: 'CP_PID',
        cp_sl: 'CP_SL',
        cp_outreach_status: 'CP_Outreach_Status',
        cp_last_contact_date: 'CP_Last_Contact_Date',
        cp_last_contact_face: 'CP_Last_Contact_Face',
        cp_contact_face: 'CP_Contact_Face',
        cp_participation_form_date: 'CP_Participation_Form_Date',
        cp_care_plan_sent_pcp_date: 'CP_Care_Plan_Sent_PCP_Date',
        cp_care_plan_returned_pcp_date: 'CP_Care_Plan_Returned_PCP_Date',
        key_contact_name_first: 'Key_Contact_Name_First',
        key_contact_name_last: 'Key_Contact_Name_Last',
        key_contact_phone: 'Key_Contact_Phone',
        key_contact_email: 'Key_Contact_Email',
        care_coordinator_first_name: 'Care_Coordinator_Name_First',
        care_coordinator_last_name: 'Care_Coordinator_Name_Last',
        care_coordinator_phone: 'Care_Coordinator_Phone',
        care_coordinator_email: 'Care_Coordinator_Email',
        report_start_date: 'Report_Start_Date',
        report_end_date: 'Report_End_Date',
        record_status: 'Record_Status',
        record_update_date: 'Record_Update_Date',
        export_date: 'Export_Date',
      }
    end

    def any_face_to_face_for_patient_in_range(patient)
      return unless patient.present?

      if patient.face_to_face_contact_in_range? report_range
        'Y'
      else
        'N'
      end
    end

    def client_recent_face_to_face qa # rubocop:disable Naming/MethodParameterName
      if Health::QualifyingActivity.face_to_face?(qa&.mode_of_contact)
        'Y'
      elsif qa.present?
        'N'
      end
    end

    def patient_referrals
      Health::PatientReferral.not_confirmed_rejected.includes(patient: :qualifying_activities).preload(patient: :qualifying_activities)
    end

    private def patient_ids
      @patient_ids ||= patient_referrals.distinct.pluck(:patient_id).compact
    end

    def report_range
      (report_start_date..report_end_date)
    end

    def start_report
      update(started_at: Time.now)
    end

    def complete_report
      update(completed_at: Time.now)
    end

    def status
      if error
        error
      elsif completed_at.present?
        'Complete'
      elsif started_at.blank?
        'Queued'
      else
        "Running since #{started_at}"
      end
    end
  end
end
