module CohortColumns
  class UserNumeric1 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_1
    attribute :translation_key, String, lazy: true, default: 'User Numeric 1'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
