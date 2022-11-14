###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::CurrentSchoolAttended < Types::BaseEnum
    description 'C3.2'
    graphql_name 'CurrentSchoolAttended'
    value 'NOT_CURRENTLY_ENROLLED_IN_ANY_SCHOOL_OR_EDUCATIONAL_COURSE', '(0) Not currently enrolled in any school or educational course', value: 0
    value 'CURRENTLY_ENROLLED_BUT_NOT_ATTENDING_REGULARLY_WHEN_SCHOOL_OR_THE_COURSE_IS_IN_SESSION', '(1) Currently enrolled but NOT attending regularly (when school or the course is in session)', value: 1
    value 'CURRENTLY_ENROLLED_AND_ATTENDING_REGULARLY_WHEN_SCHOOL_OR_THE_COURSE_IS_IN_SESSION', '(2) Currently enrolled and attending regularly (when school or the course is in session)', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
