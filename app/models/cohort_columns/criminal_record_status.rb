module CohortColumns
  class CriminalRecordStatus < Select
    attribute :column, String, lazy: true, default: :criminal_record_status
    attribute :title, String, lazy: true, default: 'Criminal Record Status'

    def available_options
      [
        '', 
        'Open-Gather additional documentation', 
        'Outstanding Warrant', 
        'Clear', 
        'Needs Mitigation', 
        'Mitigated'
      ]
    end
  end
end
