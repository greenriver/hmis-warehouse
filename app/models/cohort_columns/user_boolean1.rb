module CohortColumns
  class UserBoolean1 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_1
    attribute :title, String, lazy: true, default: _('User Boolean 1')
  end
end
