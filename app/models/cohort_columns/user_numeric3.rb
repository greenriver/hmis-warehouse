module CohortColumns
  class UserNumeric3 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_3
    attribute :translation_key, String, lazy: true, default: 'User Numeric 3'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
