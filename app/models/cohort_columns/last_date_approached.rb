module CohortColumns
  class LastDateApproached < CohortDate
    attribute :column, String, lazy: true, default: :last_date_approached
    attribute :title, String, lazy: true, default: 'Last Date Approached'


  end
end
