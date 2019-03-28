module CohortColumns
  class AssessmentScore < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :assessment_score
    attribute :translation_key, String, lazy: true, default: 'Assessment Score for CAS'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
