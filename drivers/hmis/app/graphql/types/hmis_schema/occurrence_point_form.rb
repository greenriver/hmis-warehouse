###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::OccurrencePointForm < Types::BaseObject
    field :id, ID, null: false, extras: [:parent]
    # Which clients this data should be collected for
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: false
    # Form used for Viewing/Creating/Editing records
    field :definition, Types::Forms::FormDefinition, null: false, extras: [:parent]

    # object is a Hmis::Form::Instance

    def id(parent:)
      # Include project id (if present) so that instance is not cached for use across projects.
      [object.id, parent&.id].compact.join(':')
    end

    def data_collected_about
      object.data_collected_about || 'ALL_CLIENTS'
    end

    def definition(parent:)
      definition = load_ar_association(object, :published_definition)
      raise "Unable to load definition for instance: #{object.id}" unless definition.present?

      definition.filter_context = { project: parent } if parent.is_a?(Hmis::Hud::Project)
      definition
    end
  end
end
