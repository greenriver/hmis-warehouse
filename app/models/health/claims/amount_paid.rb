module Health::Claims
  class AmountPaid < Base
    self.table_name = :claims_amount_paid_location_month

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        year: "Year",
        month: "Month",
        ip: "IP",
        emerg: "Emerg",
        respite: "Respite",
        op: "OP",
        rx: "Rx",
        other: "Other",
        total: "Total",
      }
    end

  end
end