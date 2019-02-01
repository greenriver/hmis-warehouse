module CohortColumns
  class UserString3 < CohortString
    attribute :column, String, lazy: true, default: :user_string_3
    attribute :title, String, lazy: true, default: _('User String 3')
  end
end
