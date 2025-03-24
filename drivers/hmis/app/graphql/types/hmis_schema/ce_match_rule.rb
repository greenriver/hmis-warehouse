###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRule < Types::BaseObject
    # object is a Hmis::Ce::Match::Rule
    field :id, ID, null: false
    field :name, String, null: false
    field :owner_type, String, null: false

    def owner_type
      # TODO(#7166) revisit the difference between "owner" and "applicability". See:
      # https://github.com/greenriver/hmis-warehouse/pull/5218#discussion_r2008342245
      applicability_config = object.applicability_config.symbolize_keys

      if applicability_config[:project_types]&.any?
        'Project Type'
      elsif applicability_config[:project_funders]&.any?
        'Funder'
      else
        object.owner_type.demodulize
      end
    end
  end
end
