module Cas
  class ProjectClient < CasBase
    has_one :client, required: false
    belongs_to :data_source, required: false
    belongs_to :primary_race, required: false, primary_key: :numeric, foreign_key: :primary_race

  end
end