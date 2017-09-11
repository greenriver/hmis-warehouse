class GrdaWarehouse::HmisForm < GrdaWarehouseBase
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  belongs_to :hmis_assessment, class_name: GrdaWarehouse::HMIS::Assessment.name, primary_key: [:assessment_id, :site_id, :data_source_id], foreign_key: [:assessment_id, :site_id, :data_source_id]
  serialize :response, Hash
  serialize :answers, Hash

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

  # a display order we use on the client rollups page
  def <=>(other)
    if triage? ^ other.triage?
      return triage? ? -1 : 1
    end
    c = assessment_type <=> other.assessment_type
    c = other.collected_at <=> collected_at if c == 0
    c
  end
end