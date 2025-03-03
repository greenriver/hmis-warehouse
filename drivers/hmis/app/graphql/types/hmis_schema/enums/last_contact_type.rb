###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::LastContactType < Types::BaseEnum
    graphql_name 'LastContactType'

    [
      'Bed Night',
      'Service',
      'Current Living Situation',
      'Case Note',
      'Assessment',
      *HudUtility2024.assessment_name_by_data_collection_stage.values,
    ].map do |contact_type|
      value to_enum_key(contact_type), description: contact_type
    end
  end
end
