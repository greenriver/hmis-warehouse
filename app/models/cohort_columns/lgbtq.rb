module CohortColumns
  class Lgbtq < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :lgbtq
    attribute :title, String, lazy: true, default: 'LGBTQ'

  end
end
