module CohortColumns
  class DestinationFromHomelessness < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :destination_from_homelessness
    attribute :title, String, lazy: true, default: 'Recent Exits from Homelessness'

    def value(cohort_client) # OK
      cohort.time_dependant_client_data[cohort_client.client_id][:destination_from_homelessness]
    end
  end
end
