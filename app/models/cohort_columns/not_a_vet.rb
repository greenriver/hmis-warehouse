module CohortColumns
  class NotAVet < Select
    attribute :column, String, lazy: true, default: :not_a_vet
    attribute :title, String, lazy: true, default: 'Not a Vet'

  end
end
