module CohortColumns
  class Notes < Base
    attribute :column, String, lazy: true, default: :notes
    attribute :title, String, lazy: true, default: 'Notes'
    attribute :editable, Boolean, lazy: false, default: false

    def default_input_type
      :notes
    end

    def value(cohort_client)
      nil
    end

  end
end
