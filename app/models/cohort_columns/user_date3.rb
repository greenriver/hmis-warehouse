module CohortColumns
  class UserDate3 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_3
    attribute :translation_key, String, lazy: true, default: 'User Date 3'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
