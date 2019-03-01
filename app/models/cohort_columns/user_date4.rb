module CohortColumns
  class UserDate4 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_4
    attribute :translation_key, String, lazy: true, default: 'User Date 4'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
