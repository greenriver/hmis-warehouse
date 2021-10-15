###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides some conveniences method to all the view models
module GrdaWarehouse::Report
  class Base < GrdaWarehouseBase
    include ArelHelper
    self.abstract_class = true

    # add one useful association for every view subclass
    def self.inherited(subclass)
      subclass.primary_key = :id
      cn = subclass.name.index('Demographic') ? 'GrdaWarehouse::Hud::Client' : subclass.original_class_name
      belongs_to :original, primary_key: :id, foreign_key: :id, class_name: cn, optional: true
      super
    end

    # some convenience methods, because we seem to need to provide primary and foreign keys for all these relationships even though they're inferable

    def self.belongs(model)
      n = basename.to_s.pluralize.to_sym
      belongs_to model, primary_key: :id, foreign_key: "#{model}_id".to_sym, inverse_of: n, optional: true
    end

    def self.many(model)
      has_many model, primary_key: :id, foreign_key: "#{basename}_id".to_sym, inverse_of: basename
    end

    def self.one(model)
      has_one model, primary_key: :id, foreign_key: "#{basename}_id".to_sym, inverse_of: basename
    end

    def self.basename
      model_name.element.to_sym
    end

    # the corresponding model in the GrdaWarehouse::Hud, or other, namespace
    def self.original_class_name
      @original_class ||= "GrdaWarehouse::Hud::#{ name.gsub /.*::/, '' }"
    end

    def readonly?
      true
    end

    def self.update_fake_materialized_views
      update_recent_history_table
      update_recent_report_enrollments_table
    end

    def self.update_recent_history_table
      sql = GrdaWarehouse::ServiceHistoryService.distinct.joins(service_history_enrollment: [project: :organization]).
      where(date: [13.months.ago.beginning_of_month.to_date..Date.current.end_of_month.to_date]).
      select(*sh_columns).to_sql.gsub('FROM', 'INTO recent_service_history FROM')
      self.connection.execute <<-SQL
        DROP TABLE IF EXISTS recent_service_history;
      SQL
      self.connection.execute(sql)
      self.connection.execute('create unique index id_rsh_index on recent_service_history (id)')
      [
        :date,
        :client_id,
        :household_id,
        :project_type,
        :project_tracking_method,
        :computed_project_type,
      ].each do |column|
        self.connection.execute("create index #{column}_rsh_index on recent_service_history (#{column})")
      end
    end


    def self.source_client_table
      @source_client_table ||= begin
        table = GrdaWarehouse::Hud::Client.arel_table.dup
        table.table_alias = 'source_clients'
        table
      end
    end

    def self.destination_client_table
      @destination_client_table ||= begin
        table = GrdaWarehouse::Hud::Client.arel_table.dup
        table.table_alias = 'destination_clients'
        table
      end
    end

    def self.client_join_table
      GrdaWarehouse::WarehouseClient.arel_table
    end

    def self.update_recent_report_enrollments_table
      self.connection.execute <<-SQL
        DROP TABLE IF EXISTS recent_report_enrollments;
      SQL
      self.connection.execute(recent_enrollments_query)
      self.connection.execute('create unique index id_ret_index on recent_report_enrollments (id)')
      [
        :EntryDate,
        :client_id,
      ].each do |column|
        self.connection.execute("create index #{column}_ret_index on recent_report_enrollments (\"#{column}\")")
      end
    end

    def self.recent_enrollments_query
      range = ::Filters::DateRange.new(start: 13.months.ago.beginning_of_month.to_date, end: Date.current.end_of_month.to_date)

      d_1_start = range.start
      d_1_end = range.end
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]

      # This is a copy of the code that creates the report_enrollments view
      # combined with the limit for open during a date range from Enrollment
      # because it is way faster than limiting the view
      query =  e_t.join(source_client_table).on(
          e_t[:data_source_id].eq(source_client_table[:data_source_id]).
          and( e_t[:PersonalID].eq source_client_table[:PersonalID] ).
          and( source_client_table[:DateDeleted].eq nil )
        ).join(client_join_table).on(
          source_client_table[:id].eq client_join_table[:source_id]
        ).join(destination_client_table).on(
          destination_client_table[:id].eq(client_join_table[:destination_id]).
          and( destination_client_table[:DateDeleted].eq nil )
        ).distinct.
        project(
          *GrdaWarehouse::Hud::Enrollment.column_names.map(&:to_sym).map{ |c| e_t[c] },  # all the enrollment columns
          source_client_table[:id].as('demographic_id'),                                         # the source client id
          destination_client_table[:id].as('client_id')                                          # the destination client id
        ).where(
          e_t[:DateDeleted].eq nil
        ).
        join(ex_t, Arel::Nodes::OuterJoin).
          on(e_t[:EnrollmentID].eq(ex_t[:EnrollmentID]).
          and(e_t[:PersonalID].eq(ex_t[:PersonalID]).
          and(e_t[:data_source_id].eq(ex_t[:data_source_id])))).
        where(d_2_end.gt(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lt(d_1_end))).to_sql
      # Turn this into a table
      query.gsub('FROM', 'INTO recent_report_enrollments FROM')
    end

    def self.sh_columns
      [
        :id,
        :client_id,
        she_t[:data_source_id].to_sql,
        :date,
        she_t[:first_date_in_program].to_sql,
        she_t[:last_date_in_program].to_sql,
        she_t[:enrollment_group_id].to_sql,
        :age,
        she_t[:destination].to_sql,
        she_t[:head_of_household_id].to_sql,
        she_t[:household_id].to_sql,
        p_t[:id].as('project_id').to_sql,
        she_t[:project_type].to_sql,
        she_t[:project_tracking_method].to_sql,
        o_t[:id].as('organization_id').to_sql,
        she_t[:housing_status_at_entry].to_sql,
        she_t[:housing_status_at_exit].to_sql,
        :service_type,
        she_t[:computed_project_type].to_sql,
        she_t[:presented_as_individual].to_sql,
      ]
    end
  end
end
