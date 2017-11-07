module Health::Claims
  class Roster < Base
    self.table_name = :claims_roster

    def column_headers 
      {
        medicaid_id: "Member ID",
        last_name: "Last Name",
        first_name: "First Name",
        gender: "Sex",
        dob: "DTE_BIRTH",
        race: "Race",
        primary_language: "Primary Language",
        disability_flag: "Disability Flag",
        norm_risk_score: "Normalized risk score",
        member_months_baseline: 'MM Baseline*',
        member_months_implementation: 'MM Implementation',
        total_ty: "Total TY0817",
        cost_rank_ty: 'Cost rank TY0817',
        average_ed_visits_baseline: "Avg ED visits/ month BASELINE",
        average_ed_visits_implementation: "Avg ED visits/ month IMPLEMENT",
        average_ip_admits_baseline: "Avg IP admits/ month BASELINE",
        average_ip_admits_implementation: "Avg IP admits/ month IMPLEMENT",
        average_days_to_readmit_baseline: "Avg days to readmit BASELINE",
        average_days_to_implementation: "Avg days to readmit IMPLEMENT",
        case_manager: 'Case manager/advocate',
        housing_status: 'Housing status',
      }
    end

    def clean_rows(dirty)
      total_ty_location = column_headers.values.find_index(column_headers[:total_ty])
      dirty.map do |row|
        row[total_ty_location] = row[total_ty_location].to_i
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