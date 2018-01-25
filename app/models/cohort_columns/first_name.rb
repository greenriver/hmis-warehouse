module CohortColumns
  class FirstName < Base
    attribute :column, String, lazy: true, default: :first_name
    attribute :title, String, lazy: true, default: 'First Name'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.FirstName
    end
  end
end
