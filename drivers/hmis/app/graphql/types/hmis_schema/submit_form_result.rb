###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::SubmitFormResult < Types::BaseUnion
    description 'Union type of allowed records for form submission response'
    possible_types Types::HmisSchema::Client, Types::HmisSchema::Project, Types::HmisSchema::Organization, Types::HmisSchema::ProjectCoc, Types::HmisSchema::Funder, Types::HmisSchema::Inventory, Types::HmisSchema::Service

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
      else
        raise "#{object.class.name} is not a valid response type"
      end
    end
  end
end
