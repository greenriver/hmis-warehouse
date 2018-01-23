module CohortColumns
  class LastDateApproached < Base
    attribute :column, String, lazy: true, default: :last_date_approached
    attribute :title, String, lazy: true, default: 'Last Date Approached'

    def default_input_type
      :datetime
    end

  end
end
