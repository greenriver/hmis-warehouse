module CohortColumns
  class UserSelect2 < Select
    attribute :column, String, lazy: true, default: :user_select_2
    attribute :title, String, lazy: true, default: _('User Select 2')
  end
end
