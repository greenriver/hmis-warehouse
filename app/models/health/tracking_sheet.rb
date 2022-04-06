###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class TrackingSheet
    include ArelHelper
    include Health::CareplanDates

    def initialize(patients)
      @patient_ids = patients.map(&:id)
    end

    private def patient_ids # rubocop:disable Style/TrivialAccessors
      @patient_ids
    end

    def consented_date(patient_id)
      @consented_dates ||= Health::ParticipationForm.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:signature_on)
      @consented_dates[patient_id]&.to_date
    end

    def ssm_completed_date(patient_id)
      @ssm_completed_dates ||= Health::SelfSufficiencyMatrixForm.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:completed_at)
      @ssm_completed_dates[patient_id]&.to_date
    end

    def any_cha_completed?(patient_id)
      @patients_with_completed_chas ||= Set.new(Health::ComprehensiveHealthAssessment.completed.pluck(:patient_id))

      @patients_with_completed_chas.include?(patient_id)
    end

    def cha_renewal_completed_date(patient_id)
      @cha_completed_dates ||= Health::ComprehensiveHealthAssessment.
        completed.where(patient_id: patient_ids).
        pluck(:patient_id, :completed_at).
        group_by(&:shift).
        transform_values(&:flatten).
        reject { |_, values| values.count == 1 }. # Remove patients with only an initial CHA
        transform_values(&:max)

      @cha_completed_dates[patient_id]&.to_date
    end

    def cha_reviewed_date(patient_id)
      @cha_reviewed_dates ||= Health::ComprehensiveHealthAssessment.where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:reviewed_at)
      @cha_reviewed_dates[patient_id]&.to_date
    end

    def cha_renewal_reviewed(patient_id)
      return nil unless cha_renewal_completed_date(patient_id).present? # Ignore patients with out a completed renewal

      @patients_with_currently_reviewed_chas ||= begin
        # JOIN most_recent_assessments ON comprehensive_health_assessments.id = most_recent_assessments.current_id
        mra_t = Arel::Table.new(:most_recent_assessments)
        join = h_cha_t.join(mra_t).on(h_cha_t[:id].eq(mra_t[:current_id]))

        Set.new(Health::ComprehensiveHealthAssessment.
          with(
            most_recent_assessments:
              Health::ComprehensiveHealthAssessment.
                distinct.
                define_window(:patient_by_update).partition_by(:patient_id, order_by: { updated_at: :desc }).
                select_window(:first_value, :id, over: :patient_by_update, as: :current_id),
          ).
          joins(join.join_sources).
          where.not(reviewed_by_id: nil).
          pluck(:patient_id))
      end

      @patients_with_currently_reviewed_chas.include?(patient_id) ? 'Yes' : 'No'
    end

    def cha_initial_reviewed(patient_id)
      return nil unless any_cha_completed?(patient_id)

      @patients_with_reviewed_initial_chas ||= begin
        # JOIN oldest_assessments ON comprehensive_health_assessments.id = oldest_assessments.first_id
        oa_t = Arel::Table.new(:oldest_assessments)
        join = h_cha_t.join(oa_t).on(h_cha_t[:id].eq(oa_t[:first_id]))

        Set.new(Health::ComprehensiveHealthAssessment.
          with(
            oldest_assessments:
              Health::ComprehensiveHealthAssessment.
                distinct.
                define_window(:patient_by_update).partition_by(:patient_id, order_by: { updated_at: :desc }).
                select_window(:first_value, :id, over: :patient_by_update, as: :first_id),
          ).
          joins(join.join_sources).
          where.not(reviewed_by_id: nil).
          pluck(:patient_id))
      end

      @patients_with_reviewed_initial_chas.include?(patient_id) ? 'Yes' : 'No'
    end

    def most_recent_face_to_face_qa_date(patient_id)
      @most_recent_face_to_face_qa_dates ||= Health::QualifyingActivity.direct_contact.face_to_face.
        where(patient_id: patient_ids).
        group(:patient_id).
        maximum(:date_of_activity)
      @most_recent_face_to_face_qa_dates[patient_id]&.to_date
    end

    # def most_recent_qa_from_case_management_note patient_id
    #   @most_recent_qa_from_case_management_notes ||= Health::SdhCaseManagementNote.
    #     joins(:activities).
    #     where(patient_id: patient_ids).
    #     group(:patient_id).
    #     maximum(:date_of_contact)
    #   @most_recent_qa_from_case_management_notes[patient_id]&.to_date
    # end

    # def most_recent_qa_from_eto_case_note patient_id
    #   @eto_form_ids ||= GrdaWarehouse::HmisForm.has_qualifying_activities.pluck(:id)
    #   @most_recent_qa_from_eto_case_notes ||= Health::QualifyingActivity.
    #     where(source_type: 'GrdaWarehouse::HmisForm', source_id: @eto_form_ids).
    #     where(patient_id: patient_ids).
    #     group(:patient_id).
    #     maximum(:date_of_activity)
    #   @most_recent_qa_from_eto_case_notes[patient_id]&.to_date
    # end

    # def most_recent_qa_from_epic_case_management_note patient_id
    #   @most_recent_qa_from_epic_case_management_notes ||= Health::EpicCaseNoteQualifyingActivity.
    #     joins(:patient).
    #     merge(Health::Patient.where(id: patient_ids)).
    #     group(:patient_id).
    #     maximum(:update_date)
    #   @most_recent_qa_from_epic_case_management_notes[patient_id]&.to_date
    # end

    def most_recent_qa_from_case_note(patient_id)
      @most_recent_qa_from_case_note ||= Health::QualifyingActivity.
        where(
          source_type: [
            'GrdaWarehouse::HmisForm',
            'Health::SdhCaseManagementNote',
            'Health::EpicQualifyingActivity',
          ],
        ).
        joins(:patient).
        merge(Health::Patient.where(id: patient_ids)).
        group(:patient_id).
        maximum(:date_of_activity)
      @most_recent_qa_from_case_note[patient_id]
    end

    def cha_renewal_date(patient_id)
      reviewed_date = cha_reviewed_date(patient_id)
      return nil unless reviewed_date.present?

      reviewed_date + 1.years
    end

    def care_plan_renewal_date(patient_id)
      signed_date = care_plan_provider_signed_date(patient_id)
      return nil unless signed_date.present?

      signed_date + 1.years
    end

    def aco_name(patient_id)
      @aco_names ||= Health::AccountableCareOrganization.joins(patient_referrals: :patient).
        merge(Health::PatientReferral.current).
        merge(Health::Patient.where(id: patient_ids)).
        pluck(hp_t[:id].to_sql, :name).to_h
      @aco_names[patient_id]
    end

    def care_coordinator(patient_id)
      @patient_coordinator_lookup ||= Health::Patient.pluck(:id, :care_coordinator_id).to_h
      @care_coordinators ||= User.diet.where(id: @patient_coordinator_lookup.values).
        distinct.map { |m| [m.id, m.name] }.to_h

      @care_coordinators[@patient_coordinator_lookup[patient_id]]
    end

    def most_recent_housing_status(patient_id)
      @most_recent_housing_status ||= begin
        patient_scope = Health::Patient.
          where(id: patient_ids)

        result = patient_scope.
          with_housing_status.
          pluck(:id, :housing_status, :housing_status_timestamp).
          map { |(id, status, timestamp)| [id, { status: status, timestamp: timestamp }] }.
          to_h

        patient_scope.
          joins(:sdh_case_management_notes).
          merge(Health::SdhCaseManagementNote.with_housing_status).
          pluck(:id, h_sdhcmn_t[:housing_status].to_sql, h_sdhcmn_t[:date_of_contact].to_sql).
          each do |(id, status, timestamp)|
            result[id] ||= { status: status, timestamp: timestamp }
            result[id][:status] = status if result[id][:timestamp] < timestamp
          end

        patient_scope.
          joins(:epic_case_notes).
          merge(Health::EpicCaseNote.with_housing_status).
          pluck(:id, h_ecn_t[:homeless_status].to_sql, h_ecn_t[:contact_date].to_sql).
          each do |(id, status, timestamp)|
            result[id] ||= { status: status, timestamp: timestamp }
            result[id][:status] = status if result[id][:timestamp] < timestamp
          end

        client_to_patient = patient_scope.pluck(:client_id, :id).to_h

        GrdaWarehouse::Hud::Client.
          where(id: client_to_patient.keys).
          joins(:source_hmis_forms).
          merge(GrdaWarehouse::HmisForm.with_housing_status).
          pluck(:id, hmis_form_t[:housing_status].to_sql, hmis_form_t[:collected_at].to_sql).
          each do |(client_id, status, timestamp)|
            id = client_to_patient[client_id]
            result[id] ||= { status: status, timestamp: timestamp }
            result[id][:status] = status if result[id][:timestamp] < timestamp
          end

        result
      end
      @most_recent_housing_status[patient_id].try(:[], :status)
    end

    def sdh_risk_score(patient)
      @sdh_risk_score ||= if RailsDrivers.loaded.include?(:claims_reporting)
        medicaid_ids = Health::Patient.where(id: patient_ids).pluck(:medicaid_id)
        ClaimsReporting::Calculators::PatientSdhRiskScore.new(medicaid_ids).to_map
      else
        {}
      end

      @sdh_risk_score[patient.medicaid_id] || 'Unknown'
    end

    def disabled_client?(client)
      @disabled_client ||= begin
        client_ids = Health::Patient.where(id: patient_ids).pluck(:client_id)
        Set.new(GrdaWarehouse::Hud::Client.disabled_client_scope(client_ids: client_ids).where(id: client_ids).pluck(:id))
      end
      @disabled_client.include?(client.id)
    end

    def row patient
      {
        'ID_MEDICAID' => patient.medicaid_id,
        'NAM_FIRST' => patient.first_name,
        'NAM_LAST' => patient.last_name,
        'DTE_BIRTH' => patient.birthdate,
        'ACO_NAME' => aco_name(patient.id),
        'CARE_COORDINATOR' => care_coordinator(patient.id),
        'ASSIGNMENT_DATE' => patient.enrollment_start_date,
        'CONSENT_DATE' => consented_date(patient.id),
        # Limit SSM and CHA to warehouse versions only (per spec)
        'SSM_DATE' => ssm_completed_date(patient.id),
        'CHA_RENEWAL_DATE' => cha_renewal_completed_date(patient.id),
        'CHA_RENEWAL_REVIEWED' => cha_renewal_reviewed(patient.id),
        'CHA_EXPECTED_RENEWAL' => cha_renewal_date(patient.id),
        'CHA_INITIAL_REVIEWED' => cha_initial_reviewed(patient.id),
        'PCTP_PT_SIGN' => care_plan_patient_signed_date(patient.id),
        'CP_CARE_PLAN_SENT_PCP_DATE' => care_plan_sent_to_provider_date(patient.id),
        'PCTP_PCP_SIGN' => care_plan_provider_signed_date(patient.id),
        'PCTP_RENEWAL_DATE' => care_plan_renewal_date(patient.id),
        'QA_FACE_TO_FACE' => most_recent_face_to_face_qa_date(patient.id),
        'QA_LAST' => most_recent_qa_from_case_note(patient.id),
        'LITERALLY_HOMELESS' => patient.client.patient.client.processed_service_history&.literally_homeless_last_three_years,
        'HMIS_DISABILITY' => disabled_client?(patient.client) ? 'Y' : 'N',
        'HOUSING_STATUS' => most_recent_housing_status(patient.id),
        'CAREPLAN_SIGNED_WITHIN_122_DAYS' => with_careplans_in_122_days?(patient, as: :text),
        'SDH_RISK_SCORE' => sdh_risk_score(patient),
      }
    end
  end
end
