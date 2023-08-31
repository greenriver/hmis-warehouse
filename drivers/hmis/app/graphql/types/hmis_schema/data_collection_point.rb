###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::DataCollectionPoint < Types::BaseObject
    # Instance id - caching issues with proj? may need to add proj id
    field :id, ID, null: false
    # Title of the form
    field :title, String, null: true, extras: [:parent]
    # Which clients this data should be collected for
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: false
    # Form used for Viewing/Creating/Editing records
    field :definition, Types::Forms::FormDefinition, null: false, extras: [:parent]

    # object is a Hmis::Form::Instance

    def title(parent:)
      definition(parent: parent).title
    end

    def data_collected_about
      object.data_collected_about || 'ALL_CLIENTS'
    end

    def definition(parent:)
      raise 'Resolving on something other than project' unless parent.is_a?(Hmis::Hud::Project)

      definition = load_ar_association(object, :definition)
      raise "Unable to load definition for instance: #{object.id}" unless definition.present?

      definition.filter_context = {
        project: parent,
        # Could add in active date, or active range, if we need to apply rules based on who was funding
        # the program at the time of an enrollment. Doesn't work when resolving on project tho.
        # active_date: object.assessment_date,
      }
      definition
    end
  end
end
