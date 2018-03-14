module CohortColumns
  class SifEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :sif_eligible
    attribute :title, String, lazy: true, default: 'SIF/PACE Eligible'


  end
end
