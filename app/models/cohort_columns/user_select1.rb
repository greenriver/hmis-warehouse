module CohortColumns
  class UserSelect1 < Select
    attribute :column, String, lazy: true, default: :user_select_1
    attribute :translation_key, String, lazy: true, default: 'User Select 1'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
