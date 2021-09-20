###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A reporting table to power the population dash boards.
# One row per client per sub-population per month.

module Reporting::MonthlyReports
  class Base < ReportingBase
    include ArelHelper
    include ::Reporting::MonthlyReports::MonthlyReportCharts
    EXPIRY = if Rails.env.development? then 30.seconds else 22.hours end

    self.table_name = :warehouse_partitioned_monthly_reports

    after_initialize :set_dates
    attr_accessor :date_range

    def self.available_types
      Rails.application.config.monthly_reports[:available_types] || {
      }
    end

    def self.add_available_type(key, klass)
      available_types = Reporting::MonthlyReports::Base.available_types
      available_types[key] = klass
      Rails.application.config.monthly_reports[:available_types] = available_types
    end

    def self.class_for sub_population
      available_types[sub_population.to_sym].constantize
    end

    def self.lookback_start
      GrdaWarehouse::Config.get(:dashboard_lookback)&.to_date
    end

    def set_dates
      @date_range ||= self.class.lookback_start..Date.yesterday
      @start_date = @date_range.first
      @end_date = @date_range.last
    end

    def populate!
      populate_used_client_ids
      remove_unused_client_ids
      Reporting::MonthlyClientIds.where(report_type: self.class.name).
        distinct.
        pluck_in_batches(:client_id, batch_size: 2_500) do |batch|
          batch = batch.flatten
          clear_batch_cache
          set_enrollments_by_client(batch)
          set_prior_enrollments
          self.class.transaction do
            _clear!(batch)
            self.class.import @enrollments_by_client.values.flatten
          end
        end
      maintain_month_range_cache
    end

    private def maintain_month_range_cache
      Rails.cache.delete([self.class.name, 'month-range'])
      self.class.available_months
    end

    def self.available_months
      Rails.cache.fetch([name, 'month-range'], expires_in: EXPIRY) do
        distinct.
          order(year: :desc, month: :desc).
          pluck(:year, :month).map do |year, month|
            Date.new(year, month, 1)
          end
      end
    end

    # NOTE: we can't truncate or clear all because we load the table in batches
    # in transactions.  If we truncated we'd have a state where only some of the
    # data was available
    def _clear! ids
      self.class.where(client_id: ids).delete_all
    end

    def remove_unused_client_ids
      self.class.where.not(client_id:
        Reporting::MonthlyClientIds.where(report_type: self.class.name).
          distinct.select(:client_id)
      ).delete_all
    end

    def populate_used_client_ids
      ids = enrollment_scope(start_date: @start_date, end_date: @end_date).
        joins(:project, :organization).
        distinct.
        pluck(:client_id).
        map{ |id| [self.class.name, id] }
      self.class.transaction do
        Reporting::MonthlyClientIds.where(report_type: self.class.name).delete_all
        Reporting::MonthlyClientIds.import([:report_type, :client_id], ids)
      end
    end

    private def clear_batch_cache
      @actives_in_month = nil # make sure we get the current batch (eventually this should get cleaned up)
      @enrollments_by_client = {}
    end

    # Group clients by month and client_id
    # Loop over all of the open enrollments,
    def set_enrollments_by_client ids
      # Cleanup RAM before starting the next batch
      GC.start
      @date_range.map{|d| [d.year, d.month]}.uniq.each do |year, month|
        # fetch open enrollments for the given month
        enrollment_scope(start_date: Date.new(year, month, 1), end_date: Date.new(year, month, -1)).
          joins(:project, :organization).
          where(client_id: ids).
          pluck(*enrollment_columns).map do |row|
            OpenStruct.new(enrollment_columns.zip(row).to_h)
          end.each do |enrollment|
          entry_month = enrollment.first_date_in_program.month
          entry_year = enrollment.first_date_in_program.year
          exit_month = enrollment.last_date_in_program&.month
          exit_year = enrollment.last_date_in_program&.year
          client_id = enrollment.client_id

          entered_in_month = entry_month == month && entry_year == year
          exited_in_month = exit_month.present? && exit_month == month && exit_year == year
          mid_month = Date.new(year, month, 15)

          client_enrollment = self.class.new(
            mid_month: mid_month,
            month: month,
            year: year,
            client_id: client_id,
            age_at_entry: enrollment[:age],
            enrollment_id: enrollment.id,
            head_of_household: enrollment[:head_of_household],
            household_id: enrollment.household_id.presence || "c_#{client_id}",
            destination_id: enrollment.destination,
            enrolled: true, # everyone will be enrolled
            active: active_in_month?(client_id: client_id, project_type: enrollment.computed_project_type, month: month, year: year, batch: ids),
            entered: entered_in_month,
            exited: exited_in_month,
            project_id: project_id(enrollment.project_id, enrollment.data_source_id),
            organization_id: organization_id(enrollment.organization_id, enrollment.data_source_id),
            project_type: enrollment.computed_project_type,
            entry_date: enrollment.first_date_in_program,
            exit_date: enrollment.last_date_in_program,
            first_enrollment: first_record?(enrollment),
            days_since_last_exit: nil,
            prior_exit_project_type: nil,
            prior_exit_destination_id: nil,

            calculated_at: Time.zone.now,
          )
          @enrollments_by_client[client_id] ||= []
          @enrollments_by_client[client_id] << client_enrollment
        end
      end
      @enrollments_by_client
    end

    def enrollment_columns
      @enrollment_columns ||= [
        :id,
        :client_id,
        :age,
        :first_date_in_program,
        :last_date_in_program,
        :project_id,
        :organization_id,
        :data_source_id,
        :head_of_household,
        :household_id,
        :computed_project_type,
        :destination,
      ]
    end

    # By client, for each enrollment that is an entry in the month,
    # figure out the most recent exit (where there wasn't an ongoing enrollment)
    # and populate the days_since_last_exit and prior_exit_project_type as appropriate
    def set_prior_enrollments
      @enrollments_by_client.each do |client_id, enrollments|
        # find the next enrollment where entered == true
        # If all other enrollments in the current month are exits and the max exit date is
        # before the entry date, make note.
        # If the prior month is empty, or only contains exits,
        # Go back in time through the enrollments looking for a month where all enrollments
        # exited == true
        # get the latest exit date
        first_month = enrollments.first.month
        first_year = enrollments.first.year
        grouped_enrollments = enrollments.group_by{|m| [m.year, m.month]}
        grouped_enrollments.each do |(year, month), ens|
          ens.each do |en|
            if en.entered
              entry_date = en.entry_date
              current_year = en.year
              current_month = en.month

              # check current month for exits
              other_enrollments_in_current_month = ens - [en]
              if other_enrollments_in_current_month.present? && other_enrollments_in_current_month.all?(&:exited)
                max_exit_enrollment = other_enrollments_in_current_month.sort_by(&:exit_date).last
                if max_exit_enrollment.exit_date < entry_date
                  en.days_since_last_exit = (en.entry_date - max_exit_enrollment.exit_date).to_i
                  en.prior_exit_project_type = max_exit_enrollment.project_type
                  en.prior_exit_destination_id = max_exit_enrollment.destination_id
                end
              elsif other_enrollments_in_current_month.present? && other_enrollments_in_current_month.all?(&:entered)
                min_entry_date = other_enrollments_in_current_month.sort_by(&:entry_date).first.entry_date
                next if min_entry_date < entry_date
              end
              next if en.days_since_last_exit.present?

              # short circuit if prior month contains ongoing enrollments
              prev = previous_month(current_year, current_month)
              previous_enrollments = grouped_enrollments[[prev.year, prev.month]]
              next if previous_enrollments.present? && ! previous_enrollments.all?(&:exited)

              # Check back through time
              while(current_year >= first_year && current_month >= first_month) do
                prev = previous_month(current_year, current_month)
                current_month = prev.month
                current_year = prev.year

                current_enrollments = grouped_enrollments[[current_year, current_month]]
                if current_enrollments.present? && current_enrollments.all?(&:exited)
                  previous_exit = current_enrollments.sort_by(&:exit_date).last
                  en.days_since_last_exit = (en.entry_date - previous_exit.exit_date).to_i
                  en.prior_exit_project_type = previous_exit.project_type
                  en.prior_exit_destination_id = previous_exit.destination_id
                  break
                end
              end
            end
          end
        end
      end
    end

    def organization_id organization_id, data_source_id
      @organziations ||= GrdaWarehouse::Hud::Organization.pluck(:id, :OrganizationID, :data_source_id).map do |id, org_id, ds_id|
        [[ds_id, org_id], id]
      end.to_h
      @organziations[[data_source_id, organization_id]]
    end

    def project_id project_id, data_source_id
      @projects ||= GrdaWarehouse::Hud::Project.pluck(:id, :ProjectID, :data_source_id).map do |id, p_id, ds_id|
        [[ds_id, p_id], id]
      end.to_h
      @projects[[data_source_id, project_id]]
    end

    def previous_month year, month
      Date.new(year, month, 1) - 1.month
    end

    def actives_in_month batch:
      @actives_in_month ||= begin
        acitives = {}
        GrdaWarehouse::ServiceHistoryService.homeless.
        where(client_id: batch).
        service_within_date_range(start_date: @start_date, end_date: @end_date).
        where(service_history_enrollment_id: enrollment_scope(start_date: @start_date, end_date: @end_date).select(:id)).
        distinct.
        pluck(
          :client_id,
          :project_type,
          Arel.sql(cast(datepart(GrdaWarehouse::ServiceHistoryService, 'month', shs_t[:date]), 'INTEGER').to_sql),
          Arel.sql(cast(datepart(GrdaWarehouse::ServiceHistoryService, 'year', shs_t[:date]), 'INTEGER').to_sql),
        ).each do |id, project_type, month, year|
          acitives[id] ||= []
          acitives[id] << [year, month, project_type]
        end
        acitives
      end
    end

    def active_in_month? client_id:, project_type:, month:, year:, batch:
      actives_in_month(batch: batch)[client_id]&.include?([year, month, project_type]) || false
    end

    def first_record? enrollment
      @first_records ||= first_scope.distinct.
        pluck(
          :client_id,
          Arel.sql(p_t[:id].to_sql),
          :first_date_in_program,
        ).map do |client_id, p_id, date|
          [client_id, [p_id, date]]
        end.to_h
      @first_records[enrollment.client_id] == [project_id(enrollment.project_id, enrollment.data_source_id), enrollment.first_date_in_program]
    end

    def enrollment_scope
      raise NotImplementedError
    end

    def sub_population_title
      raise NotImplementedError
    end

    def sub_population
      raise NotImplementedError
    end

    def active_scope start_date:, end_date:
      enrollment_scope(start_date: start_date, end_date: end_date).
        with_service_between(start_date: start_date, end_date: end_date).
        where(shs_t[:date].between(start_date..end_date))
    end

    def first_scope
      enrollment_source.first_date.where(client_id: enrollment_scope(start_date: @start_date, end_date: @end_date).select(:client_id)).
        joins(:project, :organization)
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.homeless
    end

    def self.available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_sixty_one: '25 - 61',
        over_sixty_one: '62+',
      }.invert.freeze
    end

    def self.sub_tables
      available_types.map do |name, klass|
        [
          name, {
            table_name: "warehouse_partitioned_monthly_reports_#{name}",
            type: klass,
          },
        ]
      end.to_h
    end

    def self.parent_table
      :warehouse_partitioned_monthly_reports
    end

    def self.remainder_table
      :warehouse_partitioned_monthly_reports_unknown
    end

    def self.ensure_db_structure
      ensure_tables
      ensure_triggers
    end

    def self.ensure_tables
      return if Reporting::MonthlyReports::Base.sub_tables.values.map{|m| Reporting::MonthlyReports::Base.connection.table_exists?(m[:table_name])}.all?

      if Reporting::MonthlyReports::Base.connection.table_exists? Reporting::MonthlyReports::Base.parent_table
        connection.drop_table Reporting::MonthlyReports::Base.parent_table, force: :cascade
      end

      connection.create_table Reporting::MonthlyReports::Base.parent_table do |t|
        t.integer "month", null: false
        t.integer "year", null: false
        t.string "type"
        t.integer "client_id", null: false
        t.integer "age_at_entry"
        t.integer "head_of_household", default: 0, null: false
        t.string "household_id"
        t.integer "project_id", null: false
        t.integer "organization_id", null: false
        t.integer "destination_id"
        t.boolean "first_enrollment", default: false, null: false
        t.boolean "enrolled", default: false, null: false
        t.boolean "active", default: false, null: false
        t.boolean "entered", default: false, null: false
        t.boolean "exited", default: false, null: false
        t.integer "project_type", null: false
        t.date "entry_date"
        t.date "exit_date"
        t.integer "days_since_last_exit"
        t.integer "prior_exit_project_type"
        t.integer "prior_exit_destination_id"
        t.datetime "calculated_at", null: false
        t.integer "enrollment_id"
        t.date "mid_month"
      end

      Reporting::MonthlyReports::Base.sub_tables.each do |name, details|
        table_name = details[:table_name]
        constraint = "type = '#{details[:type]}'"
        sql = "CREATE TABLE #{table_name} ( CHECK ( #{constraint} ) ) INHERITS (#{Reporting::MonthlyReports::Base.parent_table});"
        connection.execute(sql)

        connection.add_index table_name, :id, unique: true, name: "index_month_#{name}_id"
        connection.add_index table_name, :client_id, name: "index_month_#{name}_client_id"
        connection.add_index table_name, :age_at_entry, name: "index_month_#{name}_age"
        connection.add_index table_name, [:mid_month, :destination_id, :enrolled], name: "index_month_#{name}_dest_enr"
        connection.add_index table_name, [:mid_month, :active, :entered], name: "index_month_#{name}_act_enter"
        connection.add_index table_name, [:mid_month, :active, :exited], name: "index_month_#{name}_act_exit"
        connection.add_index table_name, [:mid_month, :project_type, :head_of_household], name: "index_month_#{name}_p_type_hoh"
      end
      # Don't forget the remainder
      table_name = Reporting::MonthlyReports::Base.remainder_table
      name = 'remainder'
      known = Reporting::MonthlyReports::Base.sub_tables.keys.join("', '")
      remainder_check = " type NOT IN ('#{known}') "
      sql = "CREATE TABLE #{table_name} (CHECK ( #{remainder_check} ) ) INHERITS (#{Reporting::MonthlyReports::Base.parent_table});"
      connection.execute(sql)
      connection.add_index table_name, :id, unique: true, name: "index_month_#{name}_id"
      connection.add_index table_name, :client_id, name: "index_month_#{name}_client_id"
      connection.add_index table_name, :age_at_entry, name: "index_month_#{name}_age"
      connection.add_index table_name, [:mid_month, :destination_id, :enrolled], name: "index_month_#{name}_dest_enr"
      connection.add_index table_name, [:mid_month, :active, :entered], name: "index_month_#{name}_act_enter"
      connection.add_index table_name, [:mid_month, :active, :exited], name: "index_month_#{name}_act_exit"
      connection.add_index table_name, [:mid_month, :project_type, :head_of_household], name: "index_month_#{name}_p_type_hoh"
    end

    # schema.rb doesn't include tiggers or functions
    # these need to be active for SHS to work correctly
    def self.ensure_triggers
      return if trigger_exists?

      connection.execute(trigger_sql)
    end

    def self.trigger_sql
      trigger_ifs = []
      sub_tables.each do |name, details|
        table_name = details[:table_name]
        type = details[:type]

        constraint = "NEW.type = '#{type}'"
        trigger_ifs << " ( #{constraint} ) THEN
              INSERT INTO #{table_name} VALUES (NEW.*);
          "
      end

      trigger = "
        CREATE OR REPLACE FUNCTION #{trigger_name}()
        RETURNS TRIGGER AS $$
        BEGIN
        IF "
      trigger += trigger_ifs.join(' ELSIF ');
      trigger += "
        ELSE
          INSERT INTO #{remainder_table} VALUES (NEW.*);
          END IF;
          RETURN NULL;
      END;
      $$
      LANGUAGE plpgsql;
      CREATE TRIGGER #{trigger_name}
      BEFORE INSERT ON #{parent_table}
      FOR EACH ROW EXECUTE PROCEDURE #{trigger_name}();
      "
    end

    def self.trigger_name
      'monthly_reports_insert_trigger'
    end

    def self.trigger_exists?
      query = "select count(*) from information_schema.triggers where trigger_name = '#{trigger_name}'"
      result = connection.execute(query).first
      return result['count'].positive?
    end

  end
end
