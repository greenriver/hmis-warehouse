module CohortColumns
  class UserSelect2 < Select
    attribute :column, String, lazy: true, default: :user_select_2
    attribute :translation_key, String, lazy: true, default: 'User Select 2'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
