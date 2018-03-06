module CohortColumns
  class LastGroupReviewDate < CohortDate
    attribute :column, String, lazy: true, default: :last_group_review_date
    attribute :title, String, lazy: true, default: 'Last Group Review Date'


  end
end
