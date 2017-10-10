module CohortColumns
  class Destination < Base
    attribute :column, String, lazy: true, default: :destination
    attribute :title, String, lazy: true, default: 'Destination'
    attribute :hint, String, lazy: true, default: 'Do not complete until housed.'

  end
end