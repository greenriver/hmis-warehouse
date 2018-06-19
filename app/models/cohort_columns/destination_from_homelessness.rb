module CohortColumns
  class DestinationFromHomelessness < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :destination_from_homelessness
    attribute :title, String, lazy: true, default: 'Recent Exits from Homelessness'

    def value(cohort_client) # OK
      cohort_client.destination_from_homelessness
    end
  end
end
