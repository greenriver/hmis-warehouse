###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      Types::HmisSchema::ReferralPosting,
      Types::HmisSchema::Enrollment,
      Types::HmisSchema::CurrentLivingSituation,
      Types::HmisSchema::CeAssessment,
      Types::HmisSchema::CustomCaseNote,
      Types::HmisSchema::Event,
      Types::HmisSchema::HmisParticipation,
      Types::HmisSchema::CeParticipation,
    )

    def self.resolve_type(object, _context)
      case object
      when Hmis::Hud::Client
        Types::HmisSchema::Client
      when Hmis::Hud::Project
        Types::HmisSchema::Project
      when Hmis::Hud::Organization
        Types::HmisSchema::Organization
      when Hmis::Hud::ProjectCoc
        Types::HmisSchema::ProjectCoc
      when Hmis::Hud::Funder
        Types::HmisSchema::Funder
      when Hmis::Hud::Inventory
        Types::HmisSchema::Inventory
      when Hmis::Hud::HmisService
        Types::HmisSchema::Service
      when Hmis::File
        Types::HmisSchema::File
      when HmisExternalApis::AcHmis::ReferralRequest
        Types::HmisSchema::ReferralRequest
      when HmisExternalApis::AcHmis::ReferralPosting
        Types::HmisSchema::ReferralPosting
      when Hmis::Hud::Enrollment
        Types::HmisSchema::Enrollment
      when Hmis::Hud::CurrentLivingSituation
        Types::HmisSchema::CurrentLivingSituation
      when Hmis::Hud::Assessment
        Types::HmisSchema::CeAssessment
      when Hmis::Hud::CustomCaseNote
        Types::HmisSchema::CustomCaseNote
      when Hmis::Hud::Event
        Types::HmisSchema::Event
      when Hmis::Hud::HmisParticipation
        Types::HmisSchema::HmisParticipation
      when Hmis::Hud::CeParticipation
        Types::HmisSchema::CeParticipation
      else
        raise "Invalid type: #{object.class.name}"
      end
    end
  end
end
