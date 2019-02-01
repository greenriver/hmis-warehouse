module CohortColumns
  class UserBoolean3 < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :user_boolean_3
    attribute :title, String, lazy: true, default: _('User Boolean 3')
  end
end
