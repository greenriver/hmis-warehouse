module CohortColumns
  class Lgbtq < Select
    attribute :column, String, lazy: true, default: :lgbtq
    attribute :title, String, lazy: true, default: 'LGBTQ'

  end
end
