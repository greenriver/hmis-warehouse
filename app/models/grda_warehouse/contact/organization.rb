module GrdaWarehouse::Contact
  class Organization < Base
    belongs_to :Organization, class_name: GrdaWarehouse::Hud::Organization.name, foreign_key: :entity_id

  end
end