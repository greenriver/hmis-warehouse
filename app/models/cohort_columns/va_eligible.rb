module CohortColumns
  class VaEligible < Base
    attribute :column, String, lazy: true, default: :va_eligible
    attribute :title, String, lazy: true, default: 'VA Eligible'

    def default_input_type
      :select2
    end

    def available_options
      ['Yes', 'No', 'No - ADT Only', 'No - Discharge', "No - Nat'l Guard", 'No - Reserves', 'No - Time']
    end
  end
end
