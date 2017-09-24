module CohortColumns
  class SifEligible < Base
    attribute :column, String, lazy: true, default: :sif_eligible
    attribute :title, String, lazy: true, default: 'SIF/PACE Eligible'

  end
end