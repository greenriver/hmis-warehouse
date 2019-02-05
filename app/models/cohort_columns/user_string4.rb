module CohortColumns
  class UserString4 < CohortString
    attribute :column, String, lazy: true, default: :user_string_4
    attribute :translation_key, String, lazy: true, default: 'User String 4'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
