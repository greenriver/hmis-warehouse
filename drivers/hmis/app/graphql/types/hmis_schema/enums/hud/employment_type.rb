###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::EmploymentType < Types::BaseEnum
    description 'R6.A'
    graphql_name 'EmploymentType'
    value 'FULL_TIME', '(1) Full-time', value: 1
    value 'PART_TIME', '(2) Part-time', value: 2
    value 'SEASONAL_SPORADIC_INCLUDING_DAY_LABOR', '(3) Seasonal / sporadic (including day labor)', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
