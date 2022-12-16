###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AssessmentRole < Types::BaseEnum
    description 'Assessment Role'
    graphql_name 'AssessmentRole'

    value 'INTAKE'
    value 'UPDATE'
    value 'ANNUAL'
    value 'EXIT'
    value 'CE'
    value 'POST_EXIT'
    value 'CUSTOM', 'Custom HMIS Assessment'
    value 'RECORD', 'Form for creating or editing resources directly'

    def self.as_data_collection_stage(role)
      case role
      when 'INTAKE'
        1
      when 'UPDATE'
        2
      when 'EXIT'
        3
      when 'ANNUAL'
        5
      when 'POST_EXIT'
        6
      else
        99
      end
    end
  end
end
