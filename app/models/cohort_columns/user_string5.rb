module CohortColumns
  class UserString5 < CohortString
    attribute :column, String, lazy: true, default: :user_string_5
    attribute :translation_key, String, lazy: true, default: 'User String 5'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
