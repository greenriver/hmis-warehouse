module CohortColumns
  class LastName < Base
    attribute :column, String, lazy: true, default: :last_name
    attribute :title, String, lazy: true, default: 'Last Name'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.LastName
    end
  end
end
