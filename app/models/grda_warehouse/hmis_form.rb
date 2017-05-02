class GrdaWarehouse::HmisForm < GrdaWarehouseBase
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  serialize :response, JSON
  serialize :answers, JSON

  scope :hud_assessment, -> { where name: 'HUD Assessment (Entry/Update/Annual/Exit)' }
  scope :triage, -> { where name: 'Triage Assessment'}

  def primary_language
    answers['sections'].each do |m|
      m['questions'].each do |m| 
        return m['answer'] if m['answer'].present? && m['question'] == 'A-2. Primary Language Spoken'
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