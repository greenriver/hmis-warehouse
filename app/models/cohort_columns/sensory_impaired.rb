module CohortColumns
  class SensoryImpaired < Base
    attribute :column, String, lazy: true, default: :sensory_impaired
    attribute :title, String, lazy: true, default: 'Sensory Impaired'

  end
end