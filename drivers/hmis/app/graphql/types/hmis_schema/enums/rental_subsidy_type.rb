###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::RentalSubsidyType < Types::BaseEnum
    description 'HUD Rental Subsidy Types'
    graphql_name 'RentalSubsidyType'

    value 'GDP_TIP', 'GPD TIP housing subsidy', value: 428
    value 'VASH', 'VASH housing subsidy', value: 419
    value 'RRH', 'RRH or equivalent subsidy', value: 431
    value 'HCV', 'HCV voucher (tenant or project based) (not dedicated)', value: 433
    value 'PHU', 'Public housing unit', value: 434
    value 'RBC', 'Rental by client, with other ongoing housing subsidy', value: 420
    value 'EHV', 'Emergency Housing Voucher', value: 436
    value 'FUP', 'Family Unification Program Voucher (FUP)', value: 437
    value 'FYI', 'Foster Youth to Independence Initiative (FYI)', value: 438
    value 'PSH', 'Permanent Supportive Housing', value: 439
    value 'OTHER', 'Other permanent housing dedicated for formerly homeless persons', value: 440
    invalid_value
  end
end
