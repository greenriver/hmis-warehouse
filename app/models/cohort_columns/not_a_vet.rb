module CohortColumns
  class NotAVet < Select
    attribute :column, String, lazy: true, default: :not_a_vet
    attribute :title, String, lazy: true, default: 'Not a Vet'


    def available_options
      [
        '', 
        'Not a Veteran',
        'Unchecked in HMIS',
        'SF-180 Ordered',
      ]
    end
  end
end
