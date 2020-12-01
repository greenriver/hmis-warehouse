module ClaimsReporting
  class PerformanceReport
    attr_accessor :month

    def initialize(month:)
      @month = month
    end

    # def to_partial_path
    #   'claims_reporting/warehouse_reports/performance/report'
    # end

    def report_date_range
      @month.beginning_of_month .. @month.end_of_month
    end

    def data
      t = medical_claims.arel_table

      scope = medical_claims.group(
        :procedure_code,
      ).select(
        :procedure_code,
        Arel.sql('*').count.as('count'),
        t[:member_id].count.as('member_count'),
        t[:paid_amount].sum.as('paid_amount_sum'),
      )

      connection.select_all(scope)
    end

    private def connection
      ClaimsReporting::MedicalClaim.connection
    end

    private def medical_claims
      ClaimsReporting::MedicalClaim.all
    end
  end
end
