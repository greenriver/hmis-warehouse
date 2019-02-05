module CohortColumns
  class DestinationFromHomelessness < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :destination_from_homelessness
    attribute :translation_key, String, lazy: true, default: 'Recent Exits from Homelessness'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.destination_from_homelessness
    end
  end
end
