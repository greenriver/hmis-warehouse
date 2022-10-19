module Types
  class HmisSchema::FunderInput < BaseInputObject
    include Types::Concerns::HasInputArguments

    def self.source_type
      Types::HmisSchema::Funder
    end

    add_input_arguments

    def to_params
      result = to_h
      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
