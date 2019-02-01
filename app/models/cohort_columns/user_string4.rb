module CohortColumns
  class UserString4 < CohortString
    attribute :column, String, lazy: true, default: :user_string_4
    attribute :title, String, lazy: true, default: _('User String 4')
  end
end
