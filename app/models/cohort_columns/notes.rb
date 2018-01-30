module CohortColumns
  class Notes < Base
    attribute :column, String, lazy: true, default: :notes
    attribute :title, String, lazy: true, default: 'Notes'

    def default_input_type
      :notes
    end

  end
end
