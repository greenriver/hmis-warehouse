module CohortColumns
  class VetSquaresConfirmed < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :vet_squares_confirmed
    attribute :translation_key, String, lazy: true, default: 'Vet Status Confirmed in Squares'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
