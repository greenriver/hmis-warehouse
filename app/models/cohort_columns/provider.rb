module CohortColumns
  class Provider < CohortString
    attribute :column, String, lazy: true, default: :provider
    attribute :title, String, lazy: true, default: 'Provider'


  end
end
