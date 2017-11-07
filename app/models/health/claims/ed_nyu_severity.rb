module Health::Claims
  class EdNyuSeverity < Base
    self.table_name = :claims_ed_nyu_severity

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        category: "Category",
        indiv_pct: "Implementation pct",
        sdh_pct: "Baseline pct",
      }
    end

    def clean_rows(dirty)
      dirty.map do |row|
        row.map do |value|
          if value == "#DIV/0!"
            nil
          else
            value
          end
        end
      end 
    end

  end
end