module Health
  class MemberStatusReport < HealthBase
    acts_as_paranoid
    has_many :member_status_report_patients
    belongs_to :user, required: true

    scope :visible_by?, -> (user) do
      if user.can_view_member_health_reports? || user.can_view_aggregate_health? || user.can_administer_health?
        all
      else
        none
      end
    end

    def run!
      start_report
      patient_referrals.each do |pr|
        patient = pr.patient
        most_recent_qualifying_activity = patient&.most_recent_direct_qualifying_activity
        patient_updated_at = [patient&.updated_at, pr&.updated_at, patient&.qualifying_activities&.maximum(:updated_at)].compact.max
        sender_cp = Health::Cp.sender.first
        attributes = {
          medicaid_id: pr.medicaid_id,
          member_first_name: pr.first_name,
          member_last_name: pr.last_name,
          member_middle_initial: pr.middle_initial,
          member_suffix: pr.suffix,
          member_date_of_birth: pr.birthdate,
          member_sex: pr.gender,
          aco_mco_name: pr.aco_name,
          aco_mco_pid: pr.aco_mco_pid,
          aco_mco_sl: pr.aco_mco_sl,
          cp_name_official: pr.cp_name_official,
          cp_pid: pr.cp_pid,
          cp_sl: pr.cp_sl,
          cp_outreach_status: pr.outreach_status,
          cp_last_contact_date: most_recent_qualifying_activity&.date_of_activity,
          cp_last_contact_face: client_recent_face_to_face(most_recent_qualifying_activity),
          cp_contact_face: any_face_to_face(patient),
          cp_participation_form_date: patient&.participation_forms&.maximum(:signature_on),
          cp_care_plan_sent_pcp_date: patient&.careplans&.maximum(:provider_signature_requested_at),
          cp_care_plan_returned_pcp_date: patient&.careplans&.maximum(:provider_signed_on),
          key_contact_name_first: sender_cp.key_contact_first_name,
          key_contact_name_last: sender_cp.key_contact_last_name,
          key_contact_phone: sender_cp.key_contact_phone&.gsub('-', '')&.truncate(10),
          key_contact_email: sender_cp.key_contact_email,
          care_coordinator_first_name: patient&.care_coordinator&.first_name,
          care_coordinator_last_name: patient&.care_coordinator&.last_name,
          care_coordinator_phone: patient&.care_coordinator&.phone&.gsub('-', '')&.truncate(10),
          care_coordinator_email: patient&.care_coordinator&.email,
          # report_start_date: report_start_date&.strftime('%Y%M%d'),
          # report_end_date: report_end_date&.strftime('%Y%M%d'),
          record_status: 'A',
          record_update_date: patient_updated_at.to_date,
          export_date: Date.today,
        }

        next unless report_range.include? patient_updated_at.to_date
        next if receiver.present? && attributes[:aco_mco_name] != receiver
        report_patient = member_status_report_patients.create!(attributes)
      end
      complete_report
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
        cp_outreach_status: 'Enrollment_Start_Date',
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
        care_coordinator_email: 'Care_Coordinator Email',
        report_start_date: 'Report_Start_Date',
        report_end_date: 'Report_End_Date',
        record_status: 'Record_Status',
        record_update_date: 'Record_Update_Date',
        export_date: 'Export_Date',
      }
    end

    def any_face_to_face patient
      if patient.present?
        if patient.face_to_face_contact_in_range? report_range
          'Y'
        else
          'N'
        end
      else
        nil
      end
    end

    def client_recent_face_to_face qa
      if Health::QualifyingActivity.face_to_face?(qa&.mode_of_contact)
        'Y'
      elsif qa.present?
        'N'
      else
        nil
      end
    end

    def patient_referrals
      Health::PatientReferral.all
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