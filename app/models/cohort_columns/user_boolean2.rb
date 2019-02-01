module CohortColumns
  class UserBoolean2 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_2
    attribute :title, String, lazy: true, default: _('User Boolean 2')
  end
end
