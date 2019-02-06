module CohortColumns
  class CaseManager < CohortString
    attribute :column, String, lazy: true, default: :case_manager
    attribute :translation_key, String, lazy: true, default: 'Case Manager'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Manually entered'
    end
  end
end
