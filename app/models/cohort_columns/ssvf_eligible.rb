module CohortColumns
  class SsvfEligible < Base
    attribute :column, Boolean, lazy: true, default: :ssvf_eligible
    attribute :title, String, lazy: true, default: 'SSVF Eligible'

    def default_input_type
      :radio_buttons
    end

    def available_options
      ['yes', 'no']
    end
  end
end
