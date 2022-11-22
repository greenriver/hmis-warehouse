###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::YesNoMissingReason < Types::BaseEnum
    description 'HUD No/Yes/Reasons for Missing Data (1.8)'
    graphql_name 'YesNoMissingReason'

    with_enum_map Hmis::FieldMap.no_yes_reasons
  end
end
