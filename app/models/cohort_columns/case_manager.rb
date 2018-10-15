module CohortColumns
  class CaseManager < CohortString
    attribute :column, String, lazy: true, default: :case_manager
    attribute :title, String, lazy: true, default: _('Case Manager')

    def description
      'Manually entered'
    end
  end
end
