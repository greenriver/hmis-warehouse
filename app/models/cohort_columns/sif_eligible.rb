module CohortColumns
  class SifEligible < Base
    attribute :column, Boolean, lazy: true, default: :sif_eligible
    attribute :title, String, lazy: true, default: 'SIF/PACE Eligible'

    def default_input_type
      :radio_buttons
    end

    def available_options
      ['yes', 'no']
    end
  end
end
