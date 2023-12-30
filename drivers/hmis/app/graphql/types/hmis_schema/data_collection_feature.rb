###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::DataCollectionFeature < Types::BaseObject
    skip_activity_log
    field :id, ID, null: false
    field :role, Types::Forms::Enums::DataCollectionFeatureRole, null: false
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: false

    # Don't allow adding NEW records if this is legacy. It should just be used for viewing/editing.
    field :legacy, Boolean, null: false
  end
end
