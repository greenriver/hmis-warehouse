module CohortColumns
  class UserDate3 < CohortDate
    attribute :column, String, lazy: true, default: :user_date_3
    attribute :title, String, lazy: true, default: _('User Date 3')
  end
end
