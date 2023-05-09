###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicQualifyingActivity < EpicBase
    phi_patient :patient_id
    phi_attr :epic_patient_id, Phi::OtherIdentifier, 'ID of patient'
    phi_attr :id, Phi::OtherIdentifier, 'ID of qualifying activity'
    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :entered_by, Phi::SmallPopulation, 'Name of person who entered the information'
    # phi_attr :role
    phi_attr :date_of_activity, Phi::Date, 'Date of activity'
    # phi_attr :activity
    # phi_attr :mode
    # phi_attr :reached

    include NotifierConfig
    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_qualifying_activities, optional: true
    has_one :patient, through: :epic_patient
    has_one :qualifying_activity, -> { where source_type: Health::EpicQualifyingActivity.name }, primary_key: :id_in_source, foreign_key: :epic_source_id

    scope :unprocessed, -> do
      where.not(id_in_source: Health::QualifyingActivity.where(source_type: name).select(:epic_source_id))
    end

    scope :processed, -> do
      joins(:qualifying_activity)
    end

    self.source_key = :QA_ID

    def self.csv_map(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        PAT_ID: :patient_id,
        QA_ID: :id_in_source,
        PAT_ENC_CSN_ID: :patient_encounter_id,
        USER_NAME: :entered_by,
        USER_PROV_TYPE: :role,
        QA_DATE: :date_of_activity,
        QA_ACTIVITY: :activity,
        QA_MODE: :mode,
        QA_REACHED: :reached,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    def create_qualifying_activity!
      # prevent duplication creation
      return true if qualifying_activity.present?
      # Don't add qualifying activities if we can't determine the patient
      return true unless patient.present?

      user = User.setup_system_user
      qa = Health::QualifyingActivity.new(
        patient_id: patient.id,
        date_of_activity: date_of_activity,
        user_full_name: entered_by,
        follow_up: 'See Epic',
        source_type: self.class.name,
        source_id: id,
        epic_source_id: id_in_source,
        user_id: user.id,
      )
      qa.assign_attributes(
        mode_of_contact: care_hub_mode_key(qa),
        reached_client: care_hub_reached_key(qa),
        activity: care_hub_activity_key(qa),
      )
      qa.save(validate: false)
    end

    def self.update_qualifying_activities!
      Health::QualifyingActivity.transaction do
        # Remember previous decisions about claim reports and payableness
        @claim_report_ids = {}
        Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
          ).where.not(
            claim_id: nil,
          ).pluck(:epic_source_id, :claim_id).each do |epic_source_id, claim_id|
            @claim_report_ids[claim_id] ||= []
            @claim_report_ids[claim_id] << epic_source_id
          end
        @force_pay_ids = Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
            force_payable: true,
          ).pluck(:epic_source_id)
        @naturally_payable_ids = Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
            naturally_payable: true,
          ).pluck(:epic_source_id)

        # remove and re-create all un-submitted qualifying activities that are backed by Epic
        Health::QualifyingActivity.unsubmitted.where(source_type: Health::EpicQualifyingActivity.name).delete_all
        unprocessed.each(&:create_qualifying_activity!)

        # restore previous decisions
        Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
            epic_source_id: @force_pay_ids,
          ).update_all(force_payable: true)
        Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
            epic_source_id: @naturally_payable_ids,
          ).update_all(naturally_payable: true)
        @claim_report_ids.each do |claim_id, epic_source_ids|
          Health::QualifyingActivity.unsubmitted.
            where(
              source_type: Health::EpicQualifyingActivity.name,
              epic_source_id: epic_source_ids,
            ).update_all(claim_id: claim_id)
        end
      end
    end

    def care_hub_reached_key(qa)
      qa.client_reached.detect { |_k, v| v[:title] == clean_reached_title }&.first
    end

    def clean_reached_title
      case reached
      when 'Collateral contact-not with client directly'
        'Collateral contact - not with client directly'
      else
        reached
      end
    end

    def care_hub_mode_key(qa)
      qa.modes_of_contact.detect { |_k, v| v[:title] == clean_mode_title }&.first
    end

    def clean_mode_title
      mode
    end

    def care_hub_activity_key(qa)
      qa.activities.detect { |_k, v| v[:title] == clean_activity_title(qa) }&.first
    end

    def clean_activity_title(qa)
      case qa.qa_version.class.name.split('::').last
      when 'QualifyingActivityV1'
        case activity
        when 'Comprehensive assessment', 'Comprehensive health assessment'
          'Comprehensive Health Assessment'
        when 'Person-Centered Treatment Plan Signed'
          'Person-Centered Treatment Plan signed'
        when 'Follow-up within 3 days of hospital discharge (with client)'
          'Follow-up from inpatient hospital discharge (with client)'
        when 'Follow up after discharge'
          'Follow-up from inpatient hospital discharge (with client)'
        when 'Support for transitions of care'
          'Care transitions (working with care team)'
        else
          activity
        end
      when 'QualifyingActivityV2'
        case activity
        when 'Comprehensive health assessment'
          'Comprehensive Assessment'
        when 'Follow up after discharge'
          'Follow-up from inpatient discharge with client (7 days)'
        when 'Care team meeting'
          'Meeting with 3+ care team members'
        when 'Person-Centered Treatment Plan Signed'
          'Care Plan completed'
        when 'Care planning'
          'Intake/reassessment (completing consent ROI, comprehensive assessment, care plan)'
        when 'Support for transitions of care'
          'Emergency Department visit (7 days)'
        else
          activity
        end
      end
    end

    def self.encounter_report_details
      {
        source: 'EPIC',
      }
    end
  end
end
