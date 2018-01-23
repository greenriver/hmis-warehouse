module CohortColumns
  class FirstDateHomeless < Base
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :title, String, lazy: true, default: 'First Date Homeless'

    def default_input_type
      :datetime
    end

  end
end
