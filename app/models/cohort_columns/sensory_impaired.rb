module CohortColumns
  class SensoryImpaired < Base
    attribute :column, String, lazy: true, default: :sensory_impaired
    attribute :title, String, lazy: true, default: 'Sensory Impaired'

    def default_input_type
      :select
    end

    def available_options
      ['No', 'Sight', 'Hearing', 'Sight and Hearing', 'Other: Must be in Notes']
    end

  end
end
