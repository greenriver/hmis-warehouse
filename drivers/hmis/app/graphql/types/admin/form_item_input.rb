#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  # This is the GraphQL input version of Types::Forms::FormItem. This input type is needed because
  # in graphql, attributes on input types can only be built-in scalar types or enums.
  class Admin::FormItemInput < Types::BaseInputObject
    argument :link_id, String, 'Unique identifier for item', required: false
    argument :data_collected_about, Types::Forms::Enums::DataCollectedAbout, required: false

    argument :required, Boolean, required: false
    argument :warn_if_empty, Boolean, required: false
    # argument :bounds, [Forms::ValueBound], required: false TODO(#6088)

    argument :type, Types::Forms::Enums::ItemType, required: false
    argument :prefill, Boolean, 'Whether to allow pre-filling this section from a previous assessment', required: false
    argument :component, Types::Forms::Enums::Component, required: false
    argument :text, String, required: false
    argument :brief_text, String, required: false
    argument :readonly_text, String, required: false
    argument :prefix, String, required: false
    argument :helper_text, String, required: false
    argument :hidden, Boolean, 'Whether the item should always be hidden', required: false
    argument :read_only, Boolean, 'Whether human editing is allowed', required: false
    argument :repeats, Boolean, 'Whether the item may repeat (for choice types, this means multiple choice)', required: false
    argument :pick_list_reference, String, required: false
    # argument :pick_list_options, [Forms::PickListOption], required: false TODO(#6087)
    argument :disabled_display, Forms::Enums::DisabledDisplay, 'How to display item if it is disabled', required: false
    argument :size, Forms::Enums::InputSize, required: false
    argument :enable_behavior, Forms::Enums::EnableBehavior, required: false
    # argument :enable_when, [Forms::EnableWhen], required: false TODO(#6088)
    # argument :initial, [Forms::InitialValue], required: false TODO(#6088)
    # argument :autofill_values, [Forms::AutofillValue], required: false TODO(#6088)
    argument :service_detail_type, Forms::Enums::ServiceDetailType, required: false

    argument :mapping, Types::Admin::FormFieldMappingInput, required: false
    argument :assessment_date, Boolean, required: false

    argument :item, ['Types::Admin::FormItemInput'], 'Nested items', required: false
  end
end
