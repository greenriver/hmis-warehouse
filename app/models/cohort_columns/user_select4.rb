module CohortColumns
  class UserSelect4 < Select
    attribute :column, String, lazy: true, default: :user_select_4
    attribute :translation_key, String, lazy: true, default: 'User Select 4'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
