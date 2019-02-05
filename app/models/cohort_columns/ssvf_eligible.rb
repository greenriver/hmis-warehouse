module CohortColumns
  class SsvfEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :ssvf_eligible
    attribute :translation_key, String, lazy: true, default: 'SSVF Eligible'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
