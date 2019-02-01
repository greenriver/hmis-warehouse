module CohortColumns
  class UserDate4 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_4
    attribute :title, String, lazy: true, default: _('User Date 4')
  end
end
