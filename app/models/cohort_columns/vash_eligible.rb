module CohortColumns
  class VashEligible < Base
    attribute :column, Boolean, lazy: true, default: :vash_eligible
    attribute :title, String, lazy: true, default: 'VASH Eligible'

    def default_input_type
      :radio_buttons
    end

    def available_options
      ['yes', 'no']
    end
  end
end
