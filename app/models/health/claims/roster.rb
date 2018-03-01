module Health::Claims
  class Roster < Base
    self.table_name = :claims_roster

    def column_headers 
      {
        medicaid_id: "id_medicaid",
        member_months_baseline: 'Baseline_mem_mos',
        member_months_implementation: 'Implement_mem_mos',
        baseline_admits: 'Baseline_admits',
        implementation_admits: 'Implement_admits',
        average_days_to_readmit_baseline: "Baseline_avg_days_readmit",
        average_days_to_implementation: "Implement_avg_days_readmit",
      }
    end

    def clean_rows(dirty)
      dirty.map do |row|
        row.map do |value|
          case value
          when 'Y'
            true
          when 'N'
            false
          when 'N/A', '#N/A', '#DIV/0!'
            nil
          else
            value
          end
        end
      end
    end

  end
end