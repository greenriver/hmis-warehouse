module CohortColumns
  class VashEligible < Base
    attribute :column, String, lazy: true, default: :vash_eligible
    attribute :title, String, lazy: true, default: 'VASH Eligible'

  end
end