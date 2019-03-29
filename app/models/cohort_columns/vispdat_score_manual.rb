module CohortColumns
  class VispdatScoreManual < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :vispdat_score_manual
    attribute :translation_key, String, lazy: true, default: 'VI-SPDAT Score'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Manually entered'
    end
  end
end
