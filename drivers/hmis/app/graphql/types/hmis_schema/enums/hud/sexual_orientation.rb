###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SexualOrientation < Types::BaseEnum
    description 'R3.1'
    graphql_name 'SexualOrientation'
    value 'HETEROSEXUAL', '(1) Heterosexual', value: 1
    value 'GAY', '(2) Gay', value: 2
    value 'LESBIAN', '(3) Lesbian', value: 3
    value 'BISEXUAL', '(4) Bisexual', value: 4
    value 'QUESTIONING_UNSURE', '(5) Questioning / unsure', value: 5
    value 'OTHER', '(6) Other', value: 6
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
