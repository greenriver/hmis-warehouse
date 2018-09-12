module CohortColumns
  class SleepingLocation < Select
    attribute :column, String, lazy: true, default: :sleeping_location
    attribute :title, String, lazy: true, default: _('Sleeping Location')

    def description
      'Manually entered'
    end

  end
end
