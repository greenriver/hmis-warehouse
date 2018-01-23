module CohortColumns
  class VashEligible < Base
    attribute :column, String, lazy: true, default: :vash_eligible
    attribute :title, String, lazy: true, default: 'VASH Eligible'

    def default_input_type
      :radio
    end

    def available_options
      ['yes', 'no']
    end
  end
end
