###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRule < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :type, HmisSchema::Enums::CeMatchRuleType, null: false, method: :rule_type
    field :owner_type, String, null: false

    def owner_type # todo @martha - discuss
      # config = object.applicability_config.symbolize_keys
      # if config[:project_funders]
      #   funders = Hmis::Hud::Funder.where(id: config[:project_funders])
      #   return funders.map(&:funder).join(', ')
      # end
      #
      # if config[:project_types]
      #   project_types = GrdaWarehouse::Lookups::ProjectType.where(id: config[:project_types])
      #   return project_types.map(&:name).join(', ')
      # end

      object.owner_type.demodulize
    end
  end
end
