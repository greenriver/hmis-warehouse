###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ContactLocation < Types::BaseEnum
    description '4.12.2'
    graphql_name 'ContactLocation'
    value 'PLACE_NOT_MEANT_FOR_HABITATION', '(1) Place not meant for habitation', value: 1
    value 'SERVICE_SETTING_NON_RESIDENTIAL', '(2) Service setting, non-residential', value: 2
    value 'SERVICE_SETTING_RESIDENTIAL', '(3) Service setting, residential', value: 3
  end
end
