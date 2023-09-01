###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::OccurrencePointForm < Types::BaseObject
    # Instance id - caching issues with proj? may need to add proj id
    field :id, ID, null: false
    # Which clients this data should be collected for
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: false
    # Form used for Viewing/Creating/Editing records
    field :definition, Types::Forms::FormDefinition, null: false, extras: [:parent]

    # object is a Hmis::Form::Instance

    def data_collected_about
      object.data_collected_about || 'ALL_CLIENTS'
    end

    def definition(parent:)
      raise 'Resolving on something other than project' unless parent.is_a?(Hmis::Hud::Project)

      definition = load_ar_association(object, :definition)
      raise "Unable to load definition for instance: #{object.id}" unless definition.present?

      definition.filter_context = { project: parent }
      definition
    end
  end
end
