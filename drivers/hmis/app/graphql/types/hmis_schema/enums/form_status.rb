#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class HmisSchema::Enums::FormStatus < Types::BaseEnum
    graphql_name 'FormStatus'

    Hmis::Form::Definition::STATUSES.each_with_index do |status, index|
      value status, description: "#{index + 1} - #{status.titleize}"
    end
  end
end
