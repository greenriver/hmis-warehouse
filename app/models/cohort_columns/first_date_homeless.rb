module CohortColumns
  class FirstDateHomeless < Base
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :title, String, lazy: true, default: 'First Date Homeless'
    attribute :editable, Boolean, lazy: false, default: false

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.first_homeless_date
    end

  end
end
