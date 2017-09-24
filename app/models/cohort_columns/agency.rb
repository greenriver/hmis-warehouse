module CohortColumns
  class Agency < Base
    attribute :column, String, lazy: true, default: :agency
    attribute :title, String, lazy: true, default: 'Agency'


  end
end