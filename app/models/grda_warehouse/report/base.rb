# provides some conviences method to all the view models
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

    # some convenience methods, because we seem to need to provide primary and foreign keys for all these relationships even though they're inferrable

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
      where(date: [7.months.ago.to_date..1.months.ago.to_date]).
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

    def self.update_recent_report_enrollments_table
      range = ::Filters::DateRange.new(start: 1.years.ago.to_date, end: Date.today)
      sql = GrdaWarehouse::Report::Enrollment.open_during_range(range).to_sql.gsub('FROM', 'INTO recent_report_enrollments FROM')
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