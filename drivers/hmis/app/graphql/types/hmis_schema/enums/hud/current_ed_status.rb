###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::CurrentEdStatus < Types::BaseEnum
    description 'C3.B'
    graphql_name 'CurrentEdStatus'
    value PURSUING_A_HIGH_SCHOOL_DIPLOMA_OR_GED, '(0) Pursuing a high school diploma or GED', value: 0
    value PURSUING_ASSOCIATE_S_DEGREE, "(1) Pursuing Associate's Degree", value: 1
    value PURSUING_BACHELOR_S_DEGREE, "(2) Pursuing Bachelor's Degree", value: 2
    value PURSUING_GRADUATE_DEGREE, '(3) Pursuing Graduate Degree', value: 3
    value PURSUING_OTHER_POST_SECONDARY_CREDENTIAL, '(4) Pursuing other post-secondary credential', value: 4
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
