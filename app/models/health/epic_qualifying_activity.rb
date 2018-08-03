module Health
  class EpicQualifyingActivity < EpicBase
    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_qualifying_activities
    has_one :patient, through: :epic_patient
    has_one :qualifying_activity, -> { where source_type: Health::EpicQualifyingActivity.name }, primary_key: :id, foreign_key: :source_id

    scope :unprocessed, -> do
      where.not(id: Health::QualifyingActivity.where(source_type: name).select(:source_id))
    end

    scope :processed, -> do
      joins(:qualifying_activity)
    end

    self.source_key = :QA_ID

    def self.csv_map(version: nil)
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

      user = User.setup_system_user()
      Health::QualifyingActivity.create!(
        patient_id: patient.id,
        date_of_activity: date_of_activity,
        user_full_name: entered_by,
        mode_of_contact: care_hub_mode_key,
        reached_client: care_hub_reached_key,
        activity: care_hub_activity_key,
        follow_up: 'See Epic',
        source_type: self.class.name,
        source_id: id,
        user_id: user.id
      )
    end

    def self.update_qualifying_activities!
      Health::QualifyingActivity.transaction do
        # Remember previous decisions about claim reports and payableness
        @claim_report_ids = {}
        Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name
          ).where.not(
            claim_id: nil
          ).pluck(:source_id, :claim_id).each do |source_id, claim_id|
            @claim_report_ids[claim_id] ||= []
            @claim_report_ids[claim_id] << source_id
          end
        @force_pay_ids = Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
            force_payable: true
          ).pluck(:source_id)

        # remove and re-create all un-submitted qualifying activities that are backed by Epic
        Health::QualifyingActivity.unsubmitted.where(source_type: Health::EpicQualifyingActivity.name).delete_all
        unprocessed.each(&:create_qualifying_activity!)

        # restore previous decisions
        Health::QualifyingActivity.unsubmitted.
          where(
            source_type: Health::EpicQualifyingActivity.name,
            source_id: @force_pay_ids
          ).update_all(force_payable: true)
        @claim_report_ids.each do |claim_id, source_ids|
          Health::QualifyingActivity.unsubmitted.
            where(
              source_type: Health::EpicQualifyingActivity.name,
              source_id: source_ids
            ).update_all(claim_id: claim_id)
        end
      end
    end


    def care_hub_reached_key
      @care_hub_client_reached ||= Health::QualifyingActivity.client_reached.map do |k, reached|
        [reached[:title], k]
      end.to_h
      @care_hub_client_reached[clean_reached_title]
    end

    def clean_reached_title
      reached
    end

    def care_hub_mode_key
      @care_hub_modes_of_contact ||= Health::QualifyingActivity.modes_of_contact.map do |k, mode|
        [mode[:title], k]
      end.to_h
      @care_hub_modes_of_contact[clean_mode_title]
    end

    def clean_mode_title
      mode
    end

    def care_hub_activity_key
      @care_hub_activities ||= Health::QualifyingActivity.activities.map do |k, activity|
        [activity[:title], k]
      end.to_h
      @care_hub_activities[clean_activity_title]
    end

    def clean_activity_title
      case activity
      when 'Comprehensive assessment'
        'Comprehensive Health Assessment'
      else
        activity
      end
    end
  end
end