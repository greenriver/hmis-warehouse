module CohortColumns
  class VetSquaresConfirmed < Base
    attribute :column, Boolean, lazy: true, default: :vet_squares_confirmed
    attribute :title, String, lazy: true, default: 'Vet Status Confirmed in Squares'

    def default_input_type
      :radio_buttons
    end

    def available_options
      ['yes', 'no']
    end
  end
end
