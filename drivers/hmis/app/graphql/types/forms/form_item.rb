###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    field :editor_user_ids, [ID], 'Users who can edit this field. If null, all users can edit', null: true

    field :rule, GraphQL::Types::JSON, 'Rules that apply to this item', null: true
    field :custom_rule, GraphQL::Types::JSON, 'Custom rules that apply to this item', null: true

    # field mapping
    field :mapping, Types::Forms::FieldMapping, null: true
    field :assessment_date, Boolean, 'Whether this item corresponds to the assessment date. Must be used with DATE type. Should be used no more than once per form', null: true

    # CE Match Rules support
    field :ce_match_expression_field, String, 'The identifier used in CE Match Rule expressions (e.g. "current_age" or "cde.custom_assessment.foo").', null: true

    # nested children
    field :item, ['Types::Forms::FormItem'], 'Nested items', null: true

    # Builds a synthetic FormItem-shaped Hash suitable for use as a graphql-ruby resolver object.
    #
    # Synthetic FormItems are used when we want to expose metadata about fields that aren't
    # actually defined in a form definition — for example, client attributes (age, veteran status)
    # that are usable as CE Match Rule condition fields but have no one backing FormDefinition item.
    # graphql-ruby resolves field values by calling Hash#[] on the object, so all nullable fields
    # must be present in the hash (even if nil) to avoid resolver errors. SYNTHETIC_DEFAULTS
    # supplies those nil-safe defaults; callers only need to provide the meaningful attributes.
    SYNTHETIC_DEFAULTS = {
      'repeats' => false,
      'pick_list_reference' => nil,
      'required' => false,
      'read_only' => false,
      'warn_if_empty' => false,
      'hidden' => false,
      'disabled_display' => 'HIDDEN',
    }.freeze

    def self.build(attrs)
      SYNTHETIC_DEFAULTS.merge(attrs.stringify_keys)
    end

    # By default, disabled items are hidden. Leaving here to match legacy behavior.
    def disabled_display
      object['disabled_display'] || 'HIDDEN'
    end

    def ce_match_expression_field
      # For CDE-backed items (FormDefinition#ce_match_items): "cde.custom_assessment.{custom_field_key}"
      custom_field_key = object.dig('mapping', 'custom_field_key')
      return Hmis::Ce::Match::Expression::CdeFieldMap.field_key_for(Hmis::Ce::Match::Expression::FieldMap::CUSTOM_ASSESSMENT, custom_field_key) if custom_field_key.present?

      # For client items: the link_id itself (e.g. "current_age").
      # Only surface for known ClientFieldMap keys so we don't accidentally emit a CE identifier for
      # ordinary form items that happen to share a link_id with a client field.
      link_id = object['link_id']
      Hmis::Ce::Match::Expression::ClientFieldMap.new.all.key?(link_id&.to_sym) ? link_id : nil
    end
  end
end
