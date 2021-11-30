###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class Return < ReportingBase
    self.table_name = :warehouse_returns
    include ArelHelper
    include NotifierConfig

    def populate!
      setup_notifier('ReportingSetupJob')
      return unless source_data_scope(client_ids).exists?

      already_running = Reporting::Return.advisory_lock_exists?(Reporting::Housed::ADVISORY_LOCK_KEY)
      if already_running
        @notifier.ping('Skipping reporting database returns, already running')
        return
      end

      Reporting::Return.with_advisory_lock(Reporting::Housed::ADVISORY_LOCK_KEY) do
        stays
      end
    end

    def source_data(ids)
      source_data_scope(ids).
        order(client_id: :asc, service_history_enrollment_id: :asc, date: :asc)
    end

    private def source_data_scope(ids)
      GrdaWarehouse::ServiceHistoryService.
        joins(service_history_enrollment: [:project, :organization, :client]).
        homeless.
        where(client_id: ids).
        where(date: (Reporting::MonthlyReports::Base.lookback_start..Date.current))
    end

    # Collapse all days into consecutive stays
    def stays
      # The end result isn't huge, but we need to process this
      # in batches because the number of service records is.
      # It is safe to batch by client because this only cares about the client level detail
      self.class.where.not(client_id: client_ids).delete_all
      client_ids.each_slice(1_000).with_index do |ids, i|
        @notifier.ping("Return: Starting batch #{i + 1} in batches of 1,000, of #{client_ids.count} total clients")
        batch_of_stays = []
        cache_client = GrdaWarehouse::Hud::Client.new
        client_race_scope_limit = GrdaWarehouse::Hud::Client.where(id: ids)
        prior_day = nil
        day = nil
        start_date = nil
        end_date = nil
        length_of_stay = 0
        current_client_id = nil
        # create an array with a record for each enrollment that includes the first and last date seen
        source_data(ids).pluck_in_batches(source_columns.values, batch_size: 400_000) do |batch|
          batch.each do |row|
            day = row_to_hash(row)
            if current_client_id.blank? || current_client_id != day[:client_id]
              prior_day = day.dup
              current_client_id = day[:client_id]
              length_of_stay = 0
            end

            # add a new row if we're looking at a new enrollment or the current enrollment has a break of more than one day
            if day[:service_history_enrollment_id] != prior_day[:service_history_enrollment_id] || prior_day[:date] < (day[:date] - 1.day)
              # save off the previous stay
              prior_day[:length_of_stay] = length_of_stay
              prior_day[:start_date] = start_date
              prior_day[:end_date] = end_date
              prior_day[:race] = cache_client.race_string(scope_limit: client_race_scope_limit, destination_id: day[:client_id])

              batch_of_stays << prior_day

              # reset
              length_of_stay = 0
              start_date = nil
              end_date = nil
            end

            start_date ||= day[:date]
            end_date = day[:date]
            length_of_stay += 1
            prior_day = day
          end
        end
        # Ensure we save the last enrollment
        prior_day[:length_of_stay] = length_of_stay
        prior_day[:start_date] = start_date
        prior_day[:end_date] = end_date
        prior_day[:race] = cache_client.race_string(scope_limit: client_race_scope_limit, destination_id: prior_day[:client_id])

        batch_of_stays << prior_day

        # remove "date" from the batch, it doesn't exist in the table structure
        batch_of_stays.map! do |stay|
          stay.delete(:date)
          stay
        end

        headers = batch_of_stays.first.keys
        transaction do
          self.class.where(client_id: ids).delete_all
          self.class.import(headers, batch_of_stays.map(&:values))
          @notifier.ping("Return: Adding #{batch_of_stays.count} returns")
        end
      end
    end

    def source_columns
      @source_columns ||= {
        service_history_enrollment_id: shs_t[:service_history_enrollment_id],
        record_type: shs_t[:record_type],
        date: shs_t[:date],
        age: shs_t[:age],
        service_type: shs_t[:service_type],
        client_id: shs_t[:client_id],
        project_type: shs_t[:project_type],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_id: p_t[:id],
        hmis_project_id: p_t[:ProjectID],
        destination: she_t[:destination],
        project_name: she_t[:project_name],
        organization_id: o_t[:id],
        unaccompanied_youth: she_t[:unaccompanied_youth],
        parenting_youth: she_t[:parenting_youth],
        ethnicity: c_t[:Ethnicity],
        female: c_t[:Female],
        male: c_t[:Male],
        nosinglegender: c_t[:NoSingleGender],
        transgender: c_t[:Transgender],
        questioning: c_t[:Questioning],
        gendernone: c_t[:GenderNone],
      }.freeze
    end

    private def row_to_hash(row)
      Hash[source_columns.keys.zip(row)]
    end

    def client_ids
      @client_ids ||= Reporting::Housed.distinct.pluck(:client_id)
    end
  end
end
