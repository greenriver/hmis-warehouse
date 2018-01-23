module CohortColumns
  class SifEligible < Base
    attribute :column, String, lazy: true, default: :sif_eligible
    attribute :title, String, lazy: true, default: 'SIF/PACE Eligible'

    def default_input_type
      :radio
    end

    def available_options
      ['yes', 'no']
    end
  end
end
