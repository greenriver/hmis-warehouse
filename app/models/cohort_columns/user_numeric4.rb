module CohortColumns
  class UserNumeric4 < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :user_numeric_4
    attribute :translation_key, String, lazy: true, default: 'User Numeric 4'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
