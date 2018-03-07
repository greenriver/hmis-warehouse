module CohortColumns
  class SifEligible < Radio
    attribute :column, Boolean, lazy: true, default: :sif_eligible
    attribute :title, String, lazy: true, default: 'SIF/PACE Eligible'


  end
end
