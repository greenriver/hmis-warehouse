module CohortColumns
  class CriminalRecordStatus < Base
    attribute :column, String, lazy: true, default: :criminal_record_status
    attribute :title, String, lazy: true, default: 'Criminal Record Status'

    def default_input_type
      :select
    end

    def available_options
      ['Open-Gather additional documentation', 'Outstanding Warrant', 'Clear', 'Needs Mitigation', 'Mitigated']
    end
  end
end
