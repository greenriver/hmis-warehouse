###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormItem < Types::BaseObject
    description 'A question or group of questions'

    field :link_id, String, 'Unique identifier for item', null: false
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, 'Include this item only if the Client meets this HUD DataCollectedAbout condition', null: true
    field :funders, [HmisSchema::Enums::Hud::FundingSource], 'Include this item only for the listed funders', null: true
    field :project_types_included, [HmisSchema::Enums::ProjectType], 'Include this item only for the listed project types', null: true
    field :project_types_excluded, [HmisSchema::Enums::ProjectType], 'Exclude this item for the listed project types', null: true

    # field display
    field :type, Types::Forms::Enums::ItemType, null: false
    field :component, Types::Forms::Enums::Component, 'Component to use for display/input of this item', null: true
    field :text, String, 'Primary text for the item', null: true
    field :prefix, String, 'Prefix for the item label', null: true
    field :helper_text, String, 'Helper text for the item', null: true
    field :required, Boolean, 'Whether the item must be included in data results', null: true
    field :hidden, Boolean, 'Whether the item should always be hidden', null: true
    field :read_only, Boolean, 'Whether human editing is allowed', null: true
    field :bounds, [Forms::ValueBound], null: true
    field :repeats, Boolean, 'Whether the item may repeat (for choice types, this means multiple choice)', null: true
    field :pick_list_reference, String, 'Reference to value set of possible answer options', null: true
    field :pick_list_options, [Forms::PickListOption], 'Permitted answers, for choice items', null: true
    field :enable_behavior, Forms::Enums::EnableBehavior, null: true
    field :enable_when, [Forms::EnableWhen], null: true
    field :initial, [Forms::InitialValue], 'Initial value(s) when item is first rendered', null: true
    field :autofill_values, [Forms::AutofillValue], 'Value(s) to autofill based on conditional logic', null: true

    # field mapping
    field :record_type, Forms::Enums::RelatedRecordType, 'Record type to use for population', null: true
    field :field_name, String, 'Name of the field on the record (or on the query input type). Used for record creation/update forms and for assessment population.', null: true

    # nested children
    field :item, ['Types::Forms::FormItem'], 'Nested items', null: true
  end
end
