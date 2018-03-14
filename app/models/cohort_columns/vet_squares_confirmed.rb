module CohortColumns
  class VetSquaresConfirmed < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :vet_squares_confirmed
    attribute :title, String, lazy: true, default: 'Vet Status Confirmed in Squares'


  end
end
