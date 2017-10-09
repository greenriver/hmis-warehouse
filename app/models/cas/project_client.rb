module Cas
  class ProjectClient < CasBase
    belongs_to :client, class_name: Cas::Client.name, required: false
    belongs_to :data_source, required: false
    belongs_to :primary_race, required: false, primary_key: :numeric, foreign_key: :primary_race

  end
end