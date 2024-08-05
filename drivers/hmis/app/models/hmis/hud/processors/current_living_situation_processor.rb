###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CurrentLivingSituationProcessor < Base
    def factory_name
      :current_living_situation_factory
    end

    def relation_name
      :current_living_situation
    end

    def schema
      Types::HmisSchema::CurrentLivingSituation
    end

    # This record type can be conditionally collected on CustomAssessments
    def dependent_destroyable?
      true
    end

    def assign_metadata
      super

      current_living_situation = @processor.send(factory_name, create: false)

      if current_living_situation.verified_by_project_id
        # We collect project ID onto the non-HUD field `verified_by_project_id`, then copy the project name onto the HUD field `VerifiedBy`.
        project_name = Hmis::Hud::Project.find(current_living_situation.verified_by_project_id)&.name
        current_living_situation.verified_by = project_name&.truncate(100)
      elsif current_living_situation.verified_by
        # If verified_by_project_id is nil but verified_by is populated, null it out to match
        current_living_situation.verified_by = nil
      end
    end
  end
end
