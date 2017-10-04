module CohortColumns
  class CaseManager < Base
    attribute :column, String, lazy: true, default: :case_manager
    attribute :title, String, lazy: true, default: 'Case Manager'

  end
end