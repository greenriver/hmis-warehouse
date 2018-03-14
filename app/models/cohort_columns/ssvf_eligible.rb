module CohortColumns
  class SsvfEligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :ssvf_eligible
    attribute :title, String, lazy: true, default: 'SSVF Eligible'


  end
end
