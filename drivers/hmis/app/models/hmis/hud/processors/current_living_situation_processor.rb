###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CurrentLivingSituationProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      current_living_situation = @processor.send(factory_name)

      return super(field, value) unless attribute_name == 'verified_by_project_id'

      # convert HIDDEN to nil
      verified_by_project_id = value == Base::HIDDEN_FIELD_VALUE ? nil : value

      verified_by_project = Hmis::Hud::Project.find_by(id: verified_by_project_id) if verified_by_project_id
      # Don't raise if we can't find the project, this can happen with migrated-in values, related to the hack
      # in HmisSchema::CurrentLivingSituation; see comments there for more detail

      if verified_by_project
        # We collect project ID onto the non-HUD field `verified_by_project_id`,
        # then copy the corresponding project name onto the HUD field `VerifiedBy` (aka `verified_by`).
        current_living_situation.assign_attributes(
          verified_by_project_id: verified_by_project.id,
          verified_by: verified_by_project.name.truncate(100), # HUD spec has 100 char limit, and so does the database
        )
      elsif current_living_situation.verified_by_project_id
        # If we didn't find a verified_by_project, but the CLS already has a verified_by_project_id saved in the DB,
        # this means the value was set previously and it's being explicitly cleared by the user.
        # We therefore clear both verified_by_project_id and verified_by.
        current_living_situation.assign_attributes(
          verified_by_project_id: nil,
          verified_by: nil,
        )

        # Note that we DO NOT null out verified_by if verified_by_project_id is null and has not been previously set.
        # This allows keeping existing verified_by values, for example migrated-in values
      end
    end

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
  end
end
