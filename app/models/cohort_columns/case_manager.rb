module CohortColumns
  class CaseManager < CohortString
    attribute :column, String, lazy: true, default: :case_manager
    attribute :title, String, lazy: true, default: 'Case Manager'


  end
end
