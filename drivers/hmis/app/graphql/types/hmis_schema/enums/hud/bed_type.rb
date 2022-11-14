###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::BedType < Types::BaseEnum
    description '2.7.3'
    graphql_name 'BedType'
    value FACILITY_BASED, '(1) Facility-based', value: 1
    value VOUCHER, '(2) Voucher', value: 2
    value OTHER, '(3) Other', value: 3
  end
end
