###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::HousingAssessmentAtExit < Types::BaseEnum
    description 'W5.1'
    graphql_name 'HousingAssessmentAtExit'
    value ABLE_TO_MAINTAIN_THE_HOUSING_THEY_HAD_AT_PROJECT_ENTRY, '(1) Able to maintain the housing they had at project entry', value: 1
    value MOVED_TO_NEW_HOUSING_UNIT, '(2) Moved to new housing unit', value: 2
    value MOVED_IN_WITH_FAMILY_FRIENDS_ON_A_TEMPORARY_BASIS, '(3) Moved in with family/friends on a temporary basis', value: 3
    value MOVED_IN_WITH_FAMILY_FRIENDS_ON_A_PERMANENT_BASIS, '(4) Moved in with family/friends on a permanent basis', value: 4
    value MOVED_TO_A_TRANSITIONAL_OR_TEMPORARY_HOUSING_FACILITY_OR_PROGRAM, '(5) Moved to a transitional or temporary housing facility or program', value: 5
    value CLIENT_BECAME_HOMELESS_MOVING_TO_A_SHELTER_OR_OTHER_PLACE_UNFIT_FOR_HUMAN_HABITATION, '(6) Client became homeless - moving to a shelter or other place unfit for human habitation', value: 6
    value CLIENT_WENT_TO_JAIL_PRISON, '(7) Client went to jail/prison', value: 7
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value CLIENT_DIED, '(10) Client died', value: 10
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
