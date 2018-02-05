# provides some conveniences method to all the view models
module GrdaWarehouse::Report
  class Base < GrdaWarehouseBase
    include ArelHelper
    self.abstract_class = true

    # add one useful association for every view subclass
    def self.inherited(subclass)
      subclass.primary_key = :id
      cn = subclass.name.index('Demographic') ? 'GrdaWarehouse::Hud::Client' : subclass.original_class_name
      belongs_to :original, primary_key: :id, foreign_key: :id, class_name: cn
      super
    end

    # some convenience methods, because we seem to need to provide primary and foreign keys for all these relationships even though they're inferable

    def self.belongs(model)
      n = basename.to_s.pluralize.to_sym
      belongs_to model, primary_key: :id, foreign_key: "#{model}_id".to_sym, inverse_of: n
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
      sql = GrdaWarehouse::ServiceHistory.service.joins(project: :organization).
      where(date: [8.months.ago.beginning_of_month.to_date..Date.today.end_of_month.to_date]).
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
      @source_client_table ||= Arel::Table.new(
        GrdaWarehouse::Hud::Client.table_name
      ).tap{ |t| t.table_alias = 'source_clients' }
    end

    def self.destination_client_table
      @destination_client_table ||= Arel::Table.new(
        GrdaWarehouse::Hud::Client.table_name
      ).tap{ |t| t.table_alias = 'destination_clients' }
    end

    def self.client_join_table
      GrdaWarehouse::WarehouseClient.arel_table
    end

    def self.update_recent_report_enrollments_table
      range = ::Filters::DateRange.new(start: 1.years.ago.to_date, end: Date.today)

      d_1_start = range.start
      d_1_end = range.end
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]

      # This is a copy of the code that creates the report_enrollments view
      # combined with the limit for open during a date range from Enrollmnt
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
        ).project(
          *e_t.engine.column_names.map(&:to_sym).map{ |c| e_t[c] },  # all the enrollment columns
          source_client_table[:id].as('demographic_id'),                                         # the source client id
          destination_client_table[:id].as('client_id')                                          # the destination client id
        ).where(
          e_t[:DateDeleted].eq nil
        ).
        join(ex_t, Arel::Nodes::OuterJoin).
          on(e_t[:ProjectEntryID].eq(ex_t[:ProjectEntryID]).
          and(e_t[:PersonalID].eq(ex_t[:PersonalID]).
          and(e_t[:data_source_id].eq(ex_t[:data_source_id])))).
        where(d_2_end.gt(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lt(d_1_end))).to_sql
      # Turn this into a table
      sql = query.gsub('FROM', 'INTO recent_report_enrollments FROM')
      self.connection.execute <<-SQL
        DROP TABLE IF EXISTS recent_report_enrollments;
      SQL
      self.connection.execute(sql)
      self.connection.execute('create unique index id_ret_index on recent_report_enrollments (id)')
      [
        :EntryDate,
        :client_id,
      ].each do |column|
        self.connection.execute("create index #{column}_ret_index on recent_report_enrollments (\"#{column}\")")
      end
    end

    def self.sh_columns
      [
        :id,
        :client_id,
        :data_source_id,
        :date,
        :first_date_in_program,
        :last_date_in_program,
        :enrollment_group_id,
        :age,
        :destination,
        :head_of_household_id,
        :household_id,
        p_t[:id].as('project_id').to_sql,
        :project_type,
        :project_tracking_method,
        o_t[:id].as('organization_id').to_sql,
        :housing_status_at_entry,
        :housing_status_at_exit,
        :service_type,
        :computed_project_type,
        :presented_as_individual,
      ]
    end
  end
end