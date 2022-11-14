###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::PATHReferralOutcome < Types::BaseEnum
    description '4.16.A1'
    graphql_name 'PATHReferralOutcome'
    value 'ATTAINED', '(1) Attained', value: 1
    value 'NOT_ATTAINED', '(2) Not attained', value: 2
    value 'UNKNOWN', '(3) Unknown', value: 3
  end
end
