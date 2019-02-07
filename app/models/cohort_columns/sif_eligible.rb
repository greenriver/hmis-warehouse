module CohortColumns
  class SifEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :sif_eligible
    attribute :translation_key, String, lazy: true, default: 'SIF/PACE Eligible'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
