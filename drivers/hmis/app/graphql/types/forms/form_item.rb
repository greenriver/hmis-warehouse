###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormItem < Types::BaseObject
    skip_activity_log
    description 'A question or group of questions'

    field :link_id, String, 'Unique identifier for item', null: false
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, 'Include this item only if the Client meets this HUD DataCollectedAbout condition', null: true

    # Validation and input bounds
    field :required, Boolean, 'Whether the item must be included in data results', null: true
    field :warn_if_empty, Boolean, 'Whether to show a warning if this question is unanswered', null: true
    field :bounds, [Forms::ValueBound], 'Bounds applied to the input value', null: true

    # field display
    field :type, Types::Forms::Enums::ItemType, null: false
    field :prefill, Boolean, 'Whether to allow pre-filling this section from a previous assessment', null: true
    field :component, Types::Forms::Enums::Component, 'Component to use for display/input of this item', null: true
    field :text, String, 'Primary text for the item', null: true
    field :brief_text, String, 'Label to use for placeholder and population table', null: true
    field :readonly_text, String, 'Text to use for the item when displayed in read-only view', null: true
    field :prefix, String, 'Prefix for the item label', null: true
    field :helper_text, String, 'Helper text for the item', null: true
    field :hidden, Boolean, 'Whether the item should always be hidden', null: true
    field :read_only, Boolean, 'Whether human editing is allowed', null: true
    field :repeats, Boolean, 'Whether the item may repeat (for choice types, this means multiple choice)', null: true
    field :pick_list_reference, String, 'Reference to value set of possible answer options', null: true
    field :pick_list_options, [Forms::PickListOption], 'Permitted answers, for choice items', null: true
    field :disabled_display, Forms::Enums::DisabledDisplay, 'How to display item if it is disabled', null: true
    field :size, Forms::Enums::InputSize, 'Size of the input element', null: true
    field :enable_behavior, Forms::Enums::EnableBehavior, null: true
    field :enable_when, [Forms::EnableWhen], null: true
    field :initial, [Forms::InitialValue], 'Initial value(s) when item is first rendered', null: true
    field :autofill_values, [Forms::AutofillValue], 'Value(s) to autofill based on conditional logic', null: true
    field :service_detail_type, Forms::Enums::ServiceDetailType, 'Whether to apply this field to all clients or a single client when bulk creating', null: true, deprecation_reason: 'from old bulk services implementation, no longer supported'

    field :rule, GraphQL::Types::JSON, null: true
    field :custom_rule, GraphQL::Types::JSON, null: true

    # field mapping
    field :mapping, Types::Forms::FieldMapping, null: true
    field :assessment_date, Boolean, 'Whether this item corresponds to the assessment date. Must be used with DATE type. Should be used no more than once per form', null: true

    # nested children
    field :item, ['Types::Forms::FormItem'], 'Nested items', null: true

    # By default, disabled items are hidden. Leaving here to match legacy behavior.
    def disabled_display
      object['disabled_display'] || 'HIDDEN'
    end
  end
end
