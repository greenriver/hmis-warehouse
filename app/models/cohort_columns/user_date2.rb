module CohortColumns
  class UserDate2 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_2
    attribute :title, String, lazy: true, default: _('User Date 2')
  end
end
