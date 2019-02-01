module CohortColumns
  class UserSelect4 < Select
    attribute :column, String, lazy: true, default: :user_select_4
    attribute :title, String, lazy: true, default: _('User Select 4')
  end
end
