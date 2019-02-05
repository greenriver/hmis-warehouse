module CohortColumns
  class UserDate1 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_1
    attribute :translation_key, String, lazy: true, default: 'User Date 1'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
