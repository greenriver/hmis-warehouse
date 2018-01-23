module CohortColumns
  class LastGroupReviewDate < Base
    attribute :column, String, lazy: true, default: :last_group_review_date
    attribute :title, String, lazy: true, default: 'Last Group Review Date'

    def default_input_type
      :datetime
    end

  end
end
