module CohortColumns
  class MinimumBedroomSize < ::CohortColumns::Integer
    attribute :column, String, lazy: true, default: :minimum_bedroom_size
    attribute :title, String, lazy: true, default: 'Minimum Bedroom Size'


  end
end
