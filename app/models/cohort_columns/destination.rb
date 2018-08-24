module CohortColumns
  class Destination < Select
    attribute :column, String, lazy: true, default: :destination
    attribute :title, String, lazy: true, default: _('Destination (Program Type)')
    attribute :hint, String, lazy: true, default: 'Do not complete until housed.'

    def description
      'Manually entered destination'
    end

  end
end
