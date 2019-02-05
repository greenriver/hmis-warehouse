module CohortColumns
  class UserString3 < CohortString
    attribute :column, String, lazy: true, default: :user_string_3
    attribute :translation_key, String, lazy: true, default: 'User String 3'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
