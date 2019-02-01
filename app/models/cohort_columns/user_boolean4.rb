module CohortColumns
  class UserBoolean4 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_4
    attribute :title, String, lazy: true, default: _('User Boolean 4')
  end
end
