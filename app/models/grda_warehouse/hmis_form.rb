class GrdaWarehouse::HmisForm < GrdaWarehouseBase
  include ActionView::Helpers
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  belongs_to :hmis_assessment, class_name: GrdaWarehouse::HMIS::Assessment.name, primary_key: [:assessment_id, :site_id, :data_source_id], foreign_key: [:assessment_id, :site_id, :data_source_id]
  serialize :api_response, Hash
  serialize :answers, Hash

  delegate :details_in_window_with_release?, to: :hmis_assessment

  scope :hud_assessment, -> { where name: 'HUD Assessment (Entry/Update/Annual/Exit)' }
  scope :triage, -> { where name: 'Triage Assessment'}
  scope :confidential, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.confidential)
  end
  scope :non_confidential, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.non_confidential)
  end
  scope :window, -> do
    joins(:hmis_assessment, :client).merge(GrdaWarehouse::HMIS::Assessment.window)
  end

  scope :health, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.health)
  end
  scope :window_with_details, -> do
    window.merge(GrdaWarehouse::HMIS::Assessment.window)
  end

  scope :self_sufficiency, -> do
    where(name: 'Self-Sufficiency Matrix')
  end

  scope :collected, -> do
    where.not(collected_at: nil)
  end

  scope :case_management_notes, -> do
    where(name: ['SDH Case Management Note', 'Case Management Daily Note'])
  end

  scope :has_qualifying_activities, -> do
    where(name: ['Case Management Daily Note'])
  end

  scope :has_unprocessed_quailifying_activities, -> do
    processed_ids = Health::QualifyingActivity.where(source_type: self.name).
      distinct.
      pluck(:source_id)
    has_qualifying_activities.where.not(id: processed_ids)
  end

  scope :health_touch_points, -> do
    health_assessments = joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.health).distinct.pluck(:id)
    sdh_assessments = where(arel_table[:collection_location].matches('Social Determinants of Health%')).pluck(:id)
    where(id: health_assessments + sdh_assessments)
  end

  scope :rrh_assessment, -> do
    where(name: rrh_assessment_name)
  end

  scope :newest_first, -> do
    order(collected_at: :desc)
  end


  def primary_language
    return 'Unknown' unless answers.present?
    answers = self.answers.with_indifferent_access
    answers[:sections].each do |m|
      m[:questions].each do |m|
        return m[:answer] if m[:answer].present? && m[:question] == 'A-2. Primary Language Spoken'
      end
    end
    'Unknown'
  end

  def triage?
    name == 'Triage Assessment'
  end

  def veteran_score
    return nil unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('assessment score') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('veterans score')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def rrh_desired?
    return false unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'housing resources'
    end&.first
    return false unless relevant_section.present?
    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('would you like to be considered for rapid re-housing')
    end&.first.try(:[], :answer)
    relevant_question&.downcase == 'yes' || false
  end

  def rrh_assessment_score
    return nil unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('assessment score') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase == 'boston coordinated entry assessment total score'
    end&.first.try(:[], :answer)
    relevant_question
  end

  def youth_rrh_desired?
    return false unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'housing resources'
    end&.first
    return false unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include? "it looks like you have a head of household who is 24 years old"
    end&.first.try(:[], :answer)
    relevant_question&.downcase&.include?('youth') || false
  end

  def income_maximization_assistance_requested?
    return false unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'housing resources'
    end&.first
    return false unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include? "increase and maximize all income sources"
    end&.first.try(:[], :answer)
    relevant_question&.downcase == 'yes' || false
  end

  def rrh_contact_info
    return nil unless name&.downcase == self.class.rrh_assessment_name.downcase
    return nil unless income_maximization_assistance_requested?
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'next steps and contact information'
    end&.first
    return nil unless relevant_section.present?
    relevant_section[:questions].map do |question|
      "<div><strong>#{question[:question]}</strong> #{question[:answer]}</div>"
    end.join(' ')
  end

  def qualifying_activities
    Health::QualifyingActivity.where(source_type: self.class.name, source_id: id)
  end

  def has_eto_qualifying_activities?
    name.in?(['Case Management Daily Note']) && eto_qualifying_activities.any?
  end

  def eto_qualifying_activities
    @eto_qualifying_activities ||= answers[:sections].select{|m| m[:section_title].include?('Qualifying Activity') && m[:questions].first[:answer].present?}
  end

  def create_qualifying_activity!
    return true unless GrdaWarehouse::Config.get(:healthcare_available)
    # Only some have qualifying activities
    return true unless has_eto_qualifying_activities?
    # prevent duplication creation
    return true if Health::QualifyingActivity.where(source_type: self.class.name, source_id: id).exists?
    # Don't add qualifying activities if we can't determine the patient
    return true unless patient = client&.destination_client&.patient


    user = User.setup_system_user()
    Health::QualifyingActivity.transaction do
      eto_qualifying_activities.each do |qa|
        activity = {
          mode_of_contact: care_hub_mode_key(qa),
          reached_client: care_hub_reached_key(qa),
          reached_client_collateral_contact: collateral_contact(qa),
          activity: care_hub_activity_key(qa),
          follow_up: follow_up(qa),
        }
        next unless activity[:follow_up] && activity[:mode_of_contact] && activity[:activity] && activity[:reached_client]
        qualifying_activity = Health::QualifyingActivity.new(
          patient_id: patient.id,
          date_of_activity: collected_at.to_date,
          user_full_name: staff,
          mode_of_contact: activity[:mode_of_contact],
          reached_client: activity[:reached_client],
          reached_client_collateral_contact: activity[:reached_client_collateral_contact],
          activity: activity[:activity],
          follow_up: activity[:follow_up],
          source_type: self.class.name,
          source_id: id,
          user_id: user.id
        )
        qualifying_activity.save if qualifying_activity.valid?
      end
    end
  end

  def follow_up qa
    qa[:questions].select{|m| m[:question] == 'Notes and follow-up'}.first.try(:[], :answer)
  end

  def collateral_contact qa
    qa[:questions].select{|m| m[:question] == 'Collateral contact - with whom?'}.first.try(:[], :answer)
  end

  def care_hub_reached_key qa
    @care_hub_client_reached ||= Health::QualifyingActivity.client_reached.map do |k, reached|
      [reached[:title], k]
    end.to_h
    @care_hub_client_reached[clean_reached_title(qa)]
  end

  def clean_reached_title qa
    qa[:questions].select{|m| m[:question] == 'Reached client?'}.first.try(:[], :answer)
  end


  def care_hub_mode_key qa
    @care_hub_modes_of_contact ||= Health::QualifyingActivity.modes_of_contact.map do |k, mode|
      [mode[:title], k]
    end.to_h
    @care_hub_modes_of_contact[clean_mode_title(qa)]
  end

  def clean_mode_title qa
    qa[:questions].select{|m| m[:question] == 'Mode of contact'}.first.try(:[], :answer)
  end

  def care_hub_activity_key qa
    @care_hub_activities ||= Health::QualifyingActivity.activities.map do |k, activity|
      [activity[:title], k]
    end.to_h
    @care_hub_activities[clean_activity_title(qa)]
  end

  def clean_activity_title qa
    activity = qa[:questions].select{|m| m[:question] == 'Which of these activities took place?'}.first.try(:[], :answer)
    case activity
    when 'Comprehensive assessment', 'Health Assessment'
      'Comprehensive Health Assessment'
    else
      activity
    end
  end



  # a display order we use on the client dashboard
  def <=>(other)
    if triage? ^ other.triage?
      return triage? ? -1 : 1
    end
    c = assessment_type <=> other.assessment_type
    c = other.collected_at <=> collected_at if c == 0
    c
  end

  def self.rrh_assessment_name
    'Boston CoC Coordinated Entry Assessment'
  end
end