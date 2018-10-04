module CohortColumns
  class ExitDestination < Select
    attribute :column, String, lazy: true, default: :exit_destination
    attribute :title, String, lazy: true, default: _('Exit Destination')

    def description
      'Manually entered destination'
    end

  end
end
