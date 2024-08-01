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
      return unless current_living_situation.verified_by_project_id

      project_name = Hmis::Hud::Project.find(current_living_situation.verified_by_project_id)&.name
      current_living_situation.verified_by = project_name
    end
  end
end
