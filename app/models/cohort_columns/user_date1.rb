module CohortColumns
  class UserDate1 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_1
    attribute :title, String, lazy: true, default: _('User Date 1')
  end
end
