module CohortColumns
  class PreContemplativeLastDateApproached < CohortDate
    attribute :column, String, lazy: true, default: :pre_contemplative_last_date_approached
    attribute :title, String, lazy: true, default: 'Pre-contemplative Last Date Approached'


  end
end
