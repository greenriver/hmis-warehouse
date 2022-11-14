###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SchoolStatus < Types::BaseEnum
    description 'R5.1'
    graphql_name 'SchoolStatus'
    value 'ATTENDING_SCHOOL_REGULARLY', '(1) Attending school regularly', value: 1
    value 'ATTENDING_SCHOOL_IRREGULARLY', '(2) Attending school irregularly', value: 2
    value 'GRADUATED_FROM_HIGH_SCHOOL', '(3) Graduated from high school', value: 3
    value 'OBTAINED_GED', '(4) Obtained GED', value: 4
    value 'DROPPED_OUT', '(5) Dropped out', value: 5
    value 'SUSPENDED', '(6) Suspended', value: 6
    value 'EXPELLED', '(7) Expelled', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
