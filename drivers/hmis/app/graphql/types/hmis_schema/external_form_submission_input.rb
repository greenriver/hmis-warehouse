###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ExternalFormSubmissionInput < BaseInputObject
    description 'External Form Submission Input'

    argument :status, HmisSchema::Enums::ExternalFormSubmissionStatus, required: false
    argument :spam, Boolean, required: false
    argument :notes, String, required: false

    def to_params
      to_h
    end
  end
end
