module Reporting
  class Return < ReportingBase
    include ArelHelper
    include TsqlImport

    def populate!
      return unless source_data.present?
      headers = source_data.first.keys
      self.transaction do
        self.class.delete_all
        insert_batch(self.class, headers, source_data.map(&:values))
      end
    end

    def source_data
      GrdaWarehouse::ServiceHistoryServices.joins(:service_history_enrollment).

    end

    def source_columns
      s.service_history_enrollment_id,
      s.record_type,
      s.date,
      s.age,
      s.service_type,
      s.client_id,
      s.project_type,
      e.first_date_in_program,
      e.last_date_in_program,
      e.project_id,
      e.destination,
      e.project_name,
      e.organization_id,
      e.unaccompanied_youth,
      e.parenting_youth
    end

    def client_ids
      @client_ids ||= Reporting::Housed.distinct.pluck(:client_id)
    end

  end
end