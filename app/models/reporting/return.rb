module Reporting
  class Return < ReportingBase
    self.table_name = :warehouse_returns
    include ArelHelper
    include TsqlImport

    def populate!
      return unless source_data.present?
      headers = stays.first.keys
      self.transaction do
        self.class.delete_all
        insert_batch(self.class, headers, stays.map(&:values))
      end
    end

    def source_data
      @source_data ||= begin
        GrdaWarehouse::ServiceHistoryService.joins(service_history_enrollment: :project).
        homeless.
        # in_project_type([1,2,4,8]).
        where(client_id: client_ids).
        where(date: ('2016-10-01'.to_date..Date.today)). # arbitrary cut-off, date of first RRH in Boston
        order(service_history_enrollment_id: :asc, date: :asc).
        pluck(*source_columns.values).map do |row|
          Hash[source_columns.keys.zip(row)]
        end
      end
    end
      # Collapse all days into consecutive stays
    def stays
      @stays ||= begin
        stays = []
        last_day = source_data.first

        start_date = nil
        end_date = nil
        length_of_stay = 0
        source_data.each do |day|
          # add a new row
          if day[:service_history_enrollment_id] != last_day[:service_history_enrollment_id] || last_day[:date] < (day[:date] - 1.day)
            # save off the previous stay
            day[:length_of_stay] = length_of_stay
            day[:start_date] = start_date
            day[:end_date] = end_date

            stays << day

            # reset
            last_enrollment = day[:service_history_enrollment_id]
            last_date = day[:date]
            length_of_stay = 0
            start_date = nil
            end_date = nil
          end

          start_date ||= day[:date]
          end_date = day[:date]
          length_of_stay += 1
          last_day = day
        end
        stays.map do |stay|
          stay.delete(:date)
          stay
        end
      end

    end

    def source_columns
      @source_columns ||= {
        service_history_enrollment_id: shs_t[:service_history_enrollment_id].to_sql,
        record_type: shs_t[:record_type].to_sql,
        date: shs_t[:date].to_sql,
        age: shs_t[:age].to_sql,
        service_type: shs_t[:service_type].to_sql,
        client_id: shs_t[:client_id].to_sql,
        project_type: shs_t[:project_type].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
        project_id: p_t[:id].to_sql,
        destination: she_t[:destination].to_sql,
        project_name: she_t[:project_name].to_sql,
        organization_id: she_t[:organization_id].to_sql,
        unaccompanied_youth: she_t[:unaccompanied_youth].to_sql,
        parenting_youth: she_t[:parenting_youth].to_sql,
      }
    end

    def client_ids
      @client_ids ||= Reporting::Housed.distinct.pluck(:client_id)
    end

  end
end