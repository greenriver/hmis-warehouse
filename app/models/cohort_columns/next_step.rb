module CohortColumns
  class NextStep < Base
    attribute :column, String, lazy: true, default: :next_step
    attribute :title, String, lazy: true, default: 'Next Step'

    def default_input_type
      :string
    end

  end
end
