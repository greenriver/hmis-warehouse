module CohortColumns
  class VashEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :vash_eligible
    attribute :title, String, lazy: true, default: 'VASH Eligible'

  end
end
