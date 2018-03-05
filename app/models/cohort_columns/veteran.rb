module CohortColumns
  class Veteran < Radio
    attribute :column, String, lazy: true, default: :veteran
    attribute :title, String, lazy: true, default: 'Veteran'


    def value(cohort_client)
      cohort_client.client.veteran?
    end
  end
end
