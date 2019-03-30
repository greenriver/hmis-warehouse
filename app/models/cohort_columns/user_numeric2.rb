module CohortColumns
  class UserNumeric2 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_2
    attribute :translation_key, String, lazy: true, default: 'User Numeric 2'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
