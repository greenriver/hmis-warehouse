###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health::Claims
  class AmountPaid < Base
    self.table_name = :claims_amount_paid_location_month

    phi_patient :medicaid_id
    # phr_attr :year, OK
    phi_attr :month, Phi::Date # OK if the year is not also included
    phi_attr :ip, Phi::NeedsReview
    phi_attr :emerg, Phi::NeedsReview
    phi_attr :respite, Phi::NeedsReview
    phi_attr :op, Phi::NeedsReview
    phi_attr :rx, Phi::NeedsReview
    phi_attr :other, Phi::NeedsReview
    phi_attr :total, Phi::NeedsReview
    phi_attr :year_month, Phi::Date
    phi_attr :study_period, Phi::Date # probably...

    scope :implementation, -> do
      where(arel_table[:study_period].matches('%Implement%'))
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