module CohortColumns
  class Gender < Base
    attribute :column, String, lazy: true, default: :gender
    attribute :title, String, lazy: true, default: 'Gender'
    attribute :editable, Boolean, lazy: false, default: false

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.gender
    end
  end
end
