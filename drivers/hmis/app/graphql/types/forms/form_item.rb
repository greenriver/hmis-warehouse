###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormItem < Types::BaseObject
    description 'Item representing a question of group in a FormDefinition'
    field :linkId, String, 'Unique identifier for item', null: false
    field :type, Types::Forms::Enums::ItemType, null: false
    # field :prefix, String, null: true
    field :prefix, String, null: true
    field :text, String, 'Primary text for the item', null: true
    field :required, Boolean, 'Whether the item must be included in data results', null: true
    field :hidden, Boolean, 'Whether the item should always be hidden', null: true
    field :readOnly, Boolean, 'Whether human editing is allowed', null: true
    field :repeats, Boolean, 'Whether the item may repeat (for choice types, this means multiple choice)', null: true
    # field :maxLength, Integer, 'No more than this many characters', null: true
    field :answerValueSet, String, 'Reference to value set of possible answer options', null: true
    # field :answerOption, [Forms::FormAnswerOption], 'Permitted answers, for choice items', null: true
    # field :enableBehavior, Forms::FormEnableBehavior, null: true
    # field :enableWhen, [Forms::Enums::FormEnableWhen], null: true
    field :item, ['Types::Forms::FormItem'], 'Nested items', null: true
  end
end
