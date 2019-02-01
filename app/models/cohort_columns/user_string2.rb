module CohortColumns
  class UserString2 < CohortString
    attribute :column, String, lazy: true, default: :user_string_2
    attribute :title, String, lazy: true, default: _('User String 2')
  end
end
