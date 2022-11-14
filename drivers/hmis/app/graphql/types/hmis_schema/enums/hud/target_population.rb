###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::TargetPopulation < Types::BaseEnum
    description '2.02.8'
    graphql_name 'TargetPopulation'
    value 'DOMESTIC_VIOLENCE_VICTIMS', '(1) Domestic violence victims', value: 1
    value 'PERSONS_WITH_HIV_AIDS', '(3) Persons with HIV/AIDS', value: 3
    value 'NOT_APPLICABLE', '(4) Not applicable', value: 4
  end
end
