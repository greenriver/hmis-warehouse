###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::Enums::ExternalFormSubmissionStatus < Types::BaseEnum
    graphql_name 'ExternalFormSubmissionStatus'

    value 'new'
    value 'reviewed'
  end
end
