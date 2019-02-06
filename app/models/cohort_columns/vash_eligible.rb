module CohortColumns
  class VashEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :vash_eligible
    attribute :translation_key, String, lazy: true, default: 'VASH Eligible'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
