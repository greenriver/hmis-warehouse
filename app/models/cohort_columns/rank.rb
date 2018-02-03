module CohortColumns
  class Rank < Base
    attribute :column, String, lazy: true, default: :rank
    attribute :title, String, lazy: true, default: 'Rank'

    def default_input_type
      :integer
    end

  end
end
