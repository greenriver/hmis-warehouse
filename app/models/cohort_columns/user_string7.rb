module CohortColumns
  class UserString7 < CohortString
    attribute :column, String, lazy: true, default: :user_string_7
    attribute :translation_key, String, lazy: true, default: 'User String 7'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
