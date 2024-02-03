###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CounselingMethod < Types::BaseEnum
    graphql_name 'CounselingMethod'
    # Used for R18 Counseling
    # Page 81 https://files.hudexchange.info/resources/documents/HMIS-Data-Dictionary-2024.pdf

    value 'INDIVIDUAL', 'Individual', value: 1
    value 'FAMILY', 'Family', value: 2
    value 'GROUP', 'Group - including peer counseling', value: 3
  end
end
