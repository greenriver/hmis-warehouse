###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::OmnisearchResult < Types::BaseUnion
    description 'Results from client/project omnisearch'
    possible_types Types::HmisSchema::Project, Types::HmisSchema::Client

    def self.resolve_type(object, _context)
      if object.is_a?(Hmis::Hud::Project)
        Types::HmisSchema::Project
      elsif object.is_a?(Hmis::Hud::Client)
        Types::HmisSchema::Client
      else
        raise "#{object.class.name} is not a valid omnisearch result"
      end
    end
  end
end
