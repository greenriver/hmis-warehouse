module CohortColumns
  class VaEligible < Base
    attribute :column, String, lazy: true, default: :va_eligible
    attribute :title, String, lazy: true, default: 'VA Eligible'

  end
end