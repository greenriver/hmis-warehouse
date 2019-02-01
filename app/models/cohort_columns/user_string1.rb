module CohortColumns
  class UserString1 < CohortString
    attribute :column, String, lazy: true, default: :user_string_1
    attribute :title, String, lazy: true, default: _('User String 1')
  end
end
