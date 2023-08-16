###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::SubmitFormResult < Types::BaseUnion
    description 'Union type of allowed records for form submission response'
    possible_types(
      Types::HmisSchema::Client,
      Types::HmisSchema::Project,
      Types::HmisSchema::Organization,
      Types::HmisSchema::ProjectCoc,
      Types::HmisSchema::Funder,
      Types::HmisSchema::Inventory,
      Types::HmisSchema::Service,
      Types::HmisSchema::File,
      Types::HmisSchema::ReferralRequest,
      Types::HmisSchema::Enrollment,
      Types::HmisSchema::CurrentLivingSituation,
      Types::HmisSchema::CeAssessment,
      Types::HmisSchema::Event,
    )

    def self.resolve_type(object, _context)
      config = Hmis::Form::Definition::FORM_ROLE_CONFIG.find do |_, value|
        value[:class_name] == object.class.name
      end&.last
      raise "#{object.class.name} is not a valid response type" unless config.present?

      config[:resolve_as].constantize
    end
  end
end
