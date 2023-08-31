###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::DataCollectionFeature < Types::BaseObject
    field :id, ID, null: false
    # Data collection role
    # TODO: should really be subset of FormRole
    field :role, Types::Forms::Enums::FormRole, null: false
    field :data_collected_about, [Types::Forms::Enums::DataCollectedAbout], null: false

    field :legacy_data_collected_about, [Types::Forms::Enums::DataCollectedAbout], null: false
    # Don't allow adding NEW records if this is legacy. It should just be used for editing.
    # This should be set to true if (1) there are only inactive forms, not active forms, and (2) there is data for it.
    field :legacy, Boolean, null: false
  end
end
