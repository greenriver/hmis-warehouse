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
        client_recent_face_to_face = if Health::QualifyingActivity.face_to_face?(most_recent_qualifying_activity&.mode_of_contact)
          'Y'
        elsif most_recent_qualifying_activity.present?
          'N'
        else
          nil
        end
        any_face_to_face = if patient.present?
          if patient.face_to_face_contact_in_range? report_range
            'Y'
          else
            'N'
          end
        else
          nil
        end
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
          cp_last_contact_face: client_recent_face_to_face,
          cp_contact_face: any_face_to_face,
          cp_participation_form_date: patient&.participation_forms&.maximum(:signature_on)&.strftime('%Y%M%d'),
          cp_care_plan_sent_pcp_date: patient&.careplans&.maximum(:provider_signature_requested_at)&.strftime('%Y%M%d'),
          cp_care_plan_returned_pcp_date: patient&.careplans&.maximum(:provider_signed_on)&.strftime('%Y%M%d'),
          key_contact_name_first: 'TODO',
          key_contact_name_last: 'TODO',
          key_contact_phone: 'TODO',
          key_contact_email: 'TODO',
          care_coordinator_first_name: patient&.care_coordinator&.first_name,
          care_coordinator_last_name: patient&.care_coordinator&.last_name,
          care_coordinator_phone: patient&.care_coordinator&.phone,
          care_coordinator_email: patient&.care_coordinator&.email,
          report_start_date: report_start_date,
          report_end_date: report_end_date,
          record_status: 'A',
          record_update_date: [patient&.updated_at, pr&.updated_at, patient&.qualifying_activities.maximum(:updated_at)].compact.max&.strftime('%Y%M%d'),
          export_date: Date.today.strftime('%Y%M%d'),
        }
        next unless report_range.include? attributes[:record_update_date]
        next if receiver.present? && attributes[:aco_mco_name] != receiver

        report_patient = member_status_report_patients.create(attributes)
      end
      complete_report
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
      if started_at.blank?
        'Queued'
      elsif completed_at.blank?
        "Running since #{started_at}"
      elsif error
        error
      else
        'Complete'
      end
    end
  end
end