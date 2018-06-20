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
  scope :health_touch_points, -> do
    where(arel_table[:collection_location].matches('Social Determinants of Health%'))
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
    return nil unless name == self.class.rrh_assessment_name
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'assessment score'
    end&.first
    return nil unless relevant_section.present?
    
    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('veterans score')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def rrh_desired?
    return false unless name == self.class.rrh_assessment_name
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
    return nil unless name == self.class.rrh_assessment_name
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'assessment score'
    end&.first
    return nil unless relevant_section.present?
    
    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase == 'boston coordinated entry assessment total score'
    end&.first.try(:[], :answer)
    relevant_question
  end

  def youth_rrh_desired?
    return false unless name == self.class.rrh_assessment_name
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
    return false unless name == self.class.rrh_assessment_name
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
    return nil unless name == self.class.rrh_assessment_name
    return nil unless income_maximization_assistance_requested?
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'next steps and contact information'
    end&.first
    return nil unless relevant_section.present?
    relevant_section[:questions].map do |question|
      "<div><strong>#{question[:question]}</strong> #{question[:answer]}</div>"
    end.join(' ')
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