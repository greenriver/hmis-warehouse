module Types
  class HmisSchema::InventoryInput < BaseInputObject
    include Types::Concerns::HasInputArguments

    def self.source_type
      Types::HmisSchema::Inventory
    end

    add_input_arguments

    def to_params
      result = to_h
      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
