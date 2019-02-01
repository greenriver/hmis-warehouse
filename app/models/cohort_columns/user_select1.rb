module CohortColumns
  class UserSelect1 < Select
    attribute :column, String, lazy: true, default: :user_select_1
    attribute :title, String, lazy: true, default: _('User Select 1')
  end
end
