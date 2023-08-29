###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::DataCollectionFeature < Types::BaseObject
    field :id, ID, null: false # instance id

    # Data collection role
    # TODO: maybe this is union type of DataCollectionRole or something.
    field :role, Types::Forms::Enums::FormRole, null: false

    # Form used for Viewing/Creating/Editing records
    # field :form_definition, Types::Forms::FormDefinition, null: false

    # Whom, of enrolled clients, data is collected for.
    # Maybe legacy needs to have this..
    field :data_collected_about, [Types::Forms::Enums::DataCollectedAbout], null: false

    field :legacy_data_collected_about, [Types::Forms::Enums::DataCollectedAbout], null: false
    # Don't allow adding NEW records if this is legacy. It should just be used for editing.
    # This should be set to true if (1) there are only inactive forms, not active forms, and (2) there is data for it.
    # Note: (?) this only applies to 'feature'-level things. think about how it would work for others.
    field :legacy, Boolean, null: false

    #   # where does this come from? the form? yeesh
    #   title: 'Move-in Date'

    # object is an OpenStruct. See Project type.
  end
end
