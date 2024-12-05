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

    # object is an OpenStruct, see Hmis::Hud::Enrollment occurrence_point_forms

    def id(parent:)
      # Include project id (if present) so that instance is not cached for use across projects.
      [object.definition.id, parent_project(parent)&.id].compact.join(':')
    end

    def definition(parent:)
      definition = object.definition
      definition.filter_context = { project: parent_project(parent) }
      definition
    end

    def data_collected_about
      object.data_collected_about || 'ALL_CLIENTS'
    end

    private def parent_project(parent)
      if parent.is_a?(Hmis::Hud::Project)
        parent
      elsif parent.is_a?(Hmis::Hud::Enrollment)
        parent.project
      end
    end
  end
end
