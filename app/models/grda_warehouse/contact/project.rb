module GrdaWarehouse::Contact
  class Project < Base
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: :entity_id

  end
end