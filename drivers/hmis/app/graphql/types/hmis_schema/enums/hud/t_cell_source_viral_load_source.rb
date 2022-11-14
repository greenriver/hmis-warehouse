###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::TCellSourceViralLoadSource < Types::BaseEnum
    description 'W4.B'
    graphql_name 'TCellSourceViralLoadSource'
    value MEDICAL_REPORT, '(1) Medical Report', value: 1
    value CLIENT_REPORT, '(2) Client Report', value: 2
    value OTHER, '(3) Other', value: 3
  end
end
