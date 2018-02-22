module Health::Claims
  class AmountPaid < Base
    self.table_name = :claims_amount_paid_location_month

    scope :implementation, -> do
      where(arel_table[:study_period].matches('%Implementation%'))
    end

    scope :baseline, -> do
      where(arel_table[:study_period].matches('%Baseline%'))
    end

    def column_headers 
      {
        medicaid_id: "ID_MEDICAID",
        year: "Year",
        month: "Month",
        year_month: 'YYYYMM',
        study_period: 'StudyPeriod',
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