module CohortColumns
  class PreContemplativeLastDateApproached < Base
    attribute :column, String, lazy: true, default: :pre_contemplative_last_date_approached
    attribute :title, String, lazy: true, default: 'Pre-contemplative Last Date Approached'

    def default_input_type
      :date
    end
  end
end
