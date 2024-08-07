###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# these map to "FormProcessors"
module Types
  class Forms::Enums::RelatedRecordType < Types::BaseEnum
    description 'Related record type for a group of questions in an assessment'
    graphql_name 'RelatedRecordType'

    Hmis::Form::RecordType.each do |record_type|
      value record_type.id, record_type.processor_name
    end
  end
end
