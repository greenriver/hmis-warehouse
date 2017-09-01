module Health::ClaimsImporter
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
        norm_risk_score: "NORM_RISK_SCORE",
        mbr_months: "Mbr mos",
        total_ty: "Total TY_0517",
        ed_visits: "ED visits",
        acute_ip_admits: "Acute IP admits",
        average_days_to_readmit: "Avg days to readmit",
        pcp: 'PCP',
        epic_team: 'Team in Epic',
      }
    end

    def clean_rows(dirty)
      disability_flag_location = column_headers.values.find_index("Disability Flag")
      total_ty_location = column_headers.values.find_index("Total TY_0517")
      average_days_to_readmit_location = column_headers.values.find_index("Avg days to readmit")
      dirty.map! do |row|
        if row[disability_flag_location] == 'Y'
          row[disability_flag_location] =  true
        elsif row[disability_flag_location] == 'N'
          row[disability_flag_location] =  false
        end
        row[total_ty_location] = row[total_ty_location].to_i #.gsub(/[^\d\.-]/,'').to_i
        row[average_days_to_readmit_location] = nil if row[average_days_to_readmit_location] == 'N/A'
        row
      end
      dirty
    end

  end
end