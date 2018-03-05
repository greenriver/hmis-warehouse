module CohortColumns
  class VaEligible < Select
    attribute :column, String, lazy: true, default: :va_eligible
    attribute :title, String, lazy: true, default: 'VA Eligible'


    def available_options
      ['Yes', 'No', 'No - ADT Only', 'No - Discharge', "No - Nat'l Guard", 'No - Reserves', 'No - Time']
    end
  end
end
