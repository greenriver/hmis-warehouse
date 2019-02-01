module CohortColumns
  class UserSelect3 < Select
    attribute :column, String, lazy: true, default: :user_select_3
    attribute :title, String, lazy: true, default: _('User Select 3')
  end
end
