module CohortColumns
  class HousedDate < CohortDate
    attribute :column, String, lazy: true, default: :housed_date
    attribute :title, String, lazy: true, default: 'Housed Date'


  end
end
