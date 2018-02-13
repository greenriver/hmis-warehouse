module CohortColumns
  class Veteran < Base
    attribute :column, String, lazy: true, default: :veteran
    attribute :title, String, lazy: true, default: 'Veteran'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.veteran?
    end
  end
end
