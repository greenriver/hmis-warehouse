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
    field :expression, String, null: false

    def owner_type
      # ==> revisit this here. applicability_config would be redundant with owner, I think we should
      # keep using owner for applicability (tho "owner" not really the right word), and for global
      # rules on project type and/or funder, then the owner would be data source.
      # for example:
      #
      #    Rule Applies to All ES Projects in HMIS
      #      { owner: hmis_data_source, applicability_config: { project_types: ['ES'] } }
      #
      #    Rule Applies to All Projects in Organization Y:
      #      { owner: organization_y, applicability_config: { }
      #
      #    Rule Applies to All VA-funded Projects in Organization Y:
      #      { owner: organization_y, applicability_config: { funders: ['VA'] } }
      #
      #
      # AKA: the "owner" determines the initial project scope, and applicability_config values can act as a "limit" on that scope.
      # Move these rule examples to Rule model if agreed
      #
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
