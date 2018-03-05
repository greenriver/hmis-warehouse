module CohortColumns
  class SsvfEligible < Radio
    attribute :column, Boolean, lazy: true, default: :ssvf_eligible
    attribute :title, String, lazy: true, default: 'SSVF Eligible'


  end
end
