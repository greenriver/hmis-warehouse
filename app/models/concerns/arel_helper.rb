###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides less verbose versions of stuff that's useful for working with arel
# these are all two letters both for maximum brevity and because this makes them more includable -- they are unlikely to be stomped on by other methods or functions
module ArelHelper
  extend ActiveSupport::Concern

  # give these methods to instances
  included do
    # Call this like qualified_column(c_t[:Gender])
    # to get back '"Client"."Gender"'
    # that you can pass to Active Record count, etc.
    # See config/initializers/arel_attributes_attribute.rb
    # This has been re-implemented as to_sql
    def qualified_column(arel_attribute)
      table = arel_attribute.relation
      connection = table.engine.connection
      table_name = connection.quote_table_name table.table_name
      column_name = connection.quote_column_name arel_attribute.name
      "#{table_name}.#{column_name}"
    end

    # NOTE: quoted_table_name must be quoted, use something like User.quoted_table_name
    def exists_sql(ar_query, quoted_table_name: ar_query.klass.quoted_table_name, alias_name: "t_#{SecureRandom.alphanumeric}", column_name: 'id')
      self.class.exists_sql(ar_query, quoted_table_name: quoted_table_name, alias_name: alias_name, column_name: column_name)
    end

    # This will create a correlated exists clause and attach it to the relation it is called in
    # it functions similar to a merge, but can be used when you need two merges with the same key
    # Usage:
    # User.joins(:role).correlated_exists(Role.health)
    def self.correlated_exists(scope, quoted_table_name: scope.klass.quoted_table_name, alias_name: "t_#{SecureRandom.alphanumeric}", column_name: 'id', negated: false)
      where(exists_sql(scope, quoted_table_name: quoted_table_name, alias_name: alias_name, column_name: column_name, negated: negated))
    end

    def self.exists_sql(ar_query, quoted_table_name: ar_query.klass.quoted_table_name, alias_name: "t_#{SecureRandom.alphanumeric}", column_name: 'id', negated: false)
      sql = ar_query.select(column_name).to_sql.
        gsub("#{quoted_table_name}.", "\"#{alias_name}\"."). # alias all columns
        gsub(quoted_table_name, "#{quoted_table_name} as \"#{alias_name}\"") # alias table
      exists_type = if negated
        'NOT EXISTS'
      else
        'EXISTS'
      end
      Arel.sql("#{exists_type} (#{sql} and #{quoted_table_name}.\"#{column_name}\" = \"#{alias_name}\".\"#{column_name}\") ")
    end

    # This method can be used to generate the select for a client's age at entry or start date (usually report start)
    # It requires the query to include both Client and ServiceHistoryEnrollment to function
    private def age_on_date(start_date)
      cast(
        datepart(
          GrdaWarehouse::ServiceHistoryEnrollment,
          'YEAR',
          nf('AGE', [nf('GREATEST', [she_t[:first_date_in_program], start_date]), c_t[:DOB]]),
        ),
        'integer',
      )
    end

    def qt(value)
      self.class.qt value
    end

    def nf(*args)
      self.class.nf(*args)
    end

    def unionize(*args)
      self.class.unionize(*args)
    end

    def add_alias(aka, table)
      self.class.add_alias aka, table
    end

    # create the COALESCE named function
    def cl(*args)
      nf('COALESCE', args)
    end

    def self.cl(*args)
      nf('COALESCE', args)
    end

    # create the CONCAT named function
    def ct(*args)
      nf('CONCAT', args)
    end

    def self.ct(*args)
      nf('CONCAT', args)
    end

    # create the GREATEST named function
    def greatest(*args)
      nf('GREATEST', args)
    end

    def self.greatest(*args)
      nf('GREATEST', args)
    end

    def any(*args)
      nf 'ANY', args
    end

    def array_agg(*args)
      nf 'ARRAY_AGG', args
    end

    def sql_array(*args)
      elements = args.map(&:to_sql)
      lit("ARRAY [#{elements.join(', ')}]")
    end

    def lit(str)
      self.class.lit str
    end

    def acase(conditions, elsewise: nil, quote: true)
      self.class.acase conditions, elsewise: elsewise, quote: quote
    end

    def cast(exp, as)
      self.class.cast exp, as
    end

    def datediff(*args)
      self.class.datediff(*args)
    end

    def seconds_diff(*args)
      self.class.seconds_diff(*args)
    end

    def datepart(*args)
      self.class.datepart(*args)
    end

    def checksum(*args)
      self.class.checksum(*args)
    end

    def confidentialized_project_name(column)
      self.class.confidentialized_project_name column
    end

    def bool_or(*args)
      self.class.bool_or(*args)
    end

    # Example
    # Returns most-recently started enrollment that matches the scope (open in 2020) for each client
    # GrdaWarehouse::ServiceHistoryEnrollment.entry.
    #  one_for_column(
    #   :first_date_in_program,
    #   source_arel_table: she_t,
    #   group_on: :client_id,
    #   scope: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(
    #     start_date: '2020-01-01'.to_date,
    #     end_date: '2020-12-31'.to_date,
    #   ),
    # )
    # NOTE: group_on must all be in the same table
    def self.one_for_column(column, source_arel_table:, group_on:, direction: :desc, scope: nil)
      most_recent = source_arel_table.alias("most_recent_#{source_arel_table.name}_#{SecureRandom.alphanumeric}".downcase)

      if scope
        source = scope.arel
        group_table = scope.arel_table
      else
        source = source_arel_table.project(source_arel_table[:id])
        group_table = source_arel_table
      end

      direction = :desc unless direction.in?([:asc, :desc])
      group_columns = Array.wrap(group_on).map { |c| group_table[c] }

      max_by_group = source.distinct_on(group_columns).
        order(*group_columns, source_arel_table[column].send(direction))

      join = source_arel_table.create_join(
        max_by_group.as(most_recent.name),
        source_arel_table.create_on(source_arel_table[:id].eq(most_recent[:id])),
      )

      joins(join)
    end
  end

  # Some shortcuts for arel tables
  def she_t
    GrdaWarehouse::ServiceHistoryEnrollment.arel_table
  end

  def shs_t
    GrdaWarehouse::ServiceHistoryService.arel_table
  end

  def shsm_t
    GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
  end

  def s_t
    GrdaWarehouse::Hud::Service.arel_table
  end

  def g_t
    GrdaWarehouse::Hud::Geography.arel_table
  end

  def e_t
    GrdaWarehouse::Hud::Enrollment.arel_table
  end

  def ec_t
    GrdaWarehouse::Hud::EnrollmentCoc.arel_table
  end

  def ex_t
    GrdaWarehouse::Hud::Exit.arel_table
  end

  def ds_t
    GrdaWarehouse::DataSource.arel_table
  end

  def c_t
    GrdaWarehouse::Hud::Client.arel_table
  end

  def cn_t
    GrdaWarehouse::ClientNotes::Base.arel_table
  end

  def p_t
    GrdaWarehouse::Hud::Project.arel_table
  end

  def pc_t
    GrdaWarehouse::Hud::ProjectCoc.arel_table
  end

  def o_t
    GrdaWarehouse::Hud::Organization.arel_table
  end

  def i_t
    GrdaWarehouse::Hud::Inventory.arel_table
  end

  def af_t
    GrdaWarehouse::Hud::Affiliation.arel_table
  end

  def as_t
    GrdaWarehouse::Hud::Assessment.arel_table
  end

  def asq_t
    GrdaWarehouse::Hud::AssessmentQuestion.arel_table
  end

  def ev_t
    GrdaWarehouse::Hud::Event.arel_table
  end

  def ch_t
    GrdaWarehouse::Chronic.arel_table
  end

  def hc_t
    GrdaWarehouse::HudChronic.arel_table
  end

  def wc_t
    GrdaWarehouse::WarehouseClient.arel_table
  end

  def wcp_t
    GrdaWarehouse::WarehouseClientsProcessed.arel_table
  end

  def ib_t
    GrdaWarehouse::Hud::IncomeBenefit.arel_table
  end

  def d_t
    GrdaWarehouse::Hud::Disability.arel_table
  end

  def hdv_t
    GrdaWarehouse::Hud::HealthAndDv.arel_table
  end

  def f_t
    GrdaWarehouse::Hud::Funder.arel_table
  end

  def cls_t
    GrdaWarehouse::Hud::CurrentLivingSituation.arel_table
  end

  def enx_t
    GrdaWarehouse::EnrollmentExtra.arel_table
  end

  def hmis_form_t
    GrdaWarehouse::HmisForm.arel_table
  end

  def hmis_c_t
    GrdaWarehouse::HmisClient.arel_table
  end

  def c_client_t
    GrdaWarehouse::CohortClient.arel_table
  end

  def c_c_change_t
    GrdaWarehouse::CohortClientChange.arel_table
  end

  def yib_t
    GrdaWarehouse::YouthIntake::Base.arel_table
  end

  def vispdat_t
    GrdaWarehouse::Vispdat::Base.arel_table
  end

  def hp_t
    Health::Patient.arel_table
  end

  def hpr_t
    Health::PatientReferral.arel_table
  end

  def hapr_t
    Health::AgencyPatientReferral.arel_table
  end

  def hqa_t
    Health::QualifyingActivity.arel_table
  end

  def hpf_t
    Health::ParticipationForm.arel_table
  end

  def hpff_t
    Health::ParticipationFormFile.arel_table
  end

  def h_ssm_t
    Health::SelfSufficiencyMatrixForm.arel_table
  end

  def h_epic_ssm_t
    Health::EpicSsm.arel_table
  end

  def h_sdhcmn_t
    Health::SdhCaseManagementNote.arel_table
  end

  def h_ehs_t
    Health::EpicHousingStatus.arel_table
  end

  def h_ecn_t
    Health::EpicCaseNote.arel_table
  end

  def h_cha_t
    Health::ComprehensiveHealthAssessment.arel_table
  end

  def h_echa_t
    Health::EpicCha.arel_table
  end

  def h_rf_t
    Health::ReleaseForm.arel_table
  end

  def h_cp_t
    Health::Careplan.arel_table
  end

  def htca_t
    Health::Tracing::Case.arel_table
  end

  def htco_t
    Health::Tracing::Contact.arel_table
  end

  def h_sd_t
    Health::StatusDate.arel_table
  end

  def r_monthly_t
    Reporting::MonthlyReports::Base.arel_table
  end

  def hr_ri_t
    HudReports::ReportInstance.arel_table
  end

  # and to the class itself (so they can be used in scopes, for example)
  class_methods do
    # convert non-node into a node
    def qt(value)
      case value
      when Arel::Attributes::Attribute, Arel::Nodes::Node, Arel::Nodes::Quoted
        value
      else
        Arel::Nodes::Quoted.new value
      end
    end

    # takes an array or list (splatted array) of tables and joins them with UNION
    def unionize(*tables)
      tables = tables.first if tables.length == 1 && tables.first.is_a?(Array)
      return tables.first unless tables.many?

      tables = tables.map { |t| t.respond_to?(:ast) ? t.ast : t }
      while tables.many?
        tables = tables.in_groups_of(2).map do |t1, t2|
          if t2
            Arel::Nodes::Union.new t1, t2
          else # we have an odd number of items
            t1
          end
        end
      end
      tables.first
    end

    # attempt to add an alias to a table-y thing
    def add_alias(aka, table) # alias is first because it is probably the lighter argument
      if table.respond_to?(:as)
        table.as(aka)
      else
        Arel::Nodes::TableAlias.new table, aka
      end
    end

    # create a named function
    #   nf 'NAME', [ arg1, arg2, arg3 ], 'alias'
    def nf(name, args = [], aka = nil)
      raise 'args must be an Array' unless args.is_a?(Array)

      Arel::Nodes::NamedFunction.new name, args.map { |v| qt v }, aka
    end

    def cl(*args)
      nf 'COALESCE', args
    end

    # bonk out a SQL literal
    def lit(str)
      Arel::Nodes::SqlLiteral.new str
    end

    # a little syntactic sugar to make a case statement
    def acase(conditions, elsewise: nil, quote: true)
      stmt = conditions.map do |c, v|
        if quote
          "WHEN (#{qt(c).to_sql}) THEN (#{qt(v).to_sql})"
        else
          "WHEN (#{c}) THEN (#{qt(v).to_sql})"
        end
      end.join ' '
      stmt += " ELSE (#{qt(elsewise).to_sql})" if elsewise.present?
      lit "CASE #{stmt} END"
    end

    # to translate between SQL Server DATEDIFF and Postgresql DATE_PART, and eventually, if need be, the equivalent mechanisms of
    # other DBMS's
    def datediff(engine, type, date_1, date_2)
      case engine.connection.adapter_name
      when /PostgreSQL|PostGIS/
        case type
        when 'day'
          Arel::Nodes::Subtraction.new(date_1, date_2)
        else
          raise NotImplementedError
        end

      when 'SQLServer'
        nf 'DATEDIFF', [lit(type), date_1, date_2]
      else
        raise NotImplementedError
      end
    end

    # to convert a pair of timestamps into a difference in seconds
    def seconds_diff(engine, date_1, date_2)
      case engine.connection.adapter_name
      when /PostgreSQL|PostGIS/
        delta = Arel::Nodes::Subtraction.new(date_1, date_2)
        nf 'EXTRACT', [lit("epoch FROM #{delta.to_sql}")]
      else
        raise NotImplementedError
      end
    end

    # to translate between SQL Server DATEPART and Postgresql DATE_PART, and eventually, if need be, the equivalent mechanisms of
    # other DBMS's
    def datepart(engine, type, date)
      case engine.connection.adapter_name
      when /PostgreSQL|PostGIS/
        date = lit "#{Arel::Nodes::Quoted.new(date).to_sql}::date" if date.is_a? String
        nf 'DATE_PART', [type, date]
      when 'SQLServer'
        nf 'DATEPART', [lit(type), date]
      else
        raise NotImplementedError
      end
    end

    # to translate between SQL Server CHECKSUM and Postgresql MD5
    def checksum(engine, fields)
      case engine.connection.adapter_name
      when /PostgreSQL|PostGIS/
        nf('md5', [nf('concat', fields)])
      when 'SQLServer'
        nf 'CHECKSUM', fields
      else
        raise NotImplementedError
      end
    end

    # bonk out a type casting
    def cast(exp, as)
      exp = qt exp
      exp = lit exp.to_sql unless exp.respond_to?(:as)
      nf 'CAST', [exp.as(as)]
    end

    def confidentialized_project_name(column)
      conditions = [
        [p_t[:confidential].eq(true).or(o_t[:confidential].eq(true)), GrdaWarehouse::Hud::Project.confidential_project_name],
      ]
      acase(conditions, elsewise: column)
    end

    def bool_or(field1, field2)
      conditions = [
        [field1.eq(true).or(field2.eq(true)), true],
      ]
      acase(conditions, elsewise: 'false')
    end

    # Some shortcuts for arel tables
    def she_t
      GrdaWarehouse::ServiceHistoryEnrollment.arel_table
    end

    def shs_t
      GrdaWarehouse::ServiceHistoryService.arel_table
    end

    def shsm_t
      GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
    end

    def s_t
      GrdaWarehouse::Hud::Service.arel_table
    end

    def g_t
      GrdaWarehouse::Hud::Geography.arel_table
    end

    def e_t
      GrdaWarehouse::Hud::Enrollment.arel_table
    end

    def ec_t
      GrdaWarehouse::Hud::EnrollmentCoc.arel_table
    end

    def ex_t
      GrdaWarehouse::Hud::Exit.arel_table
    end

    def ds_t
      GrdaWarehouse::DataSource.arel_table
    end

    def c_t
      GrdaWarehouse::Hud::Client.arel_table
    end

    def cn_t
      GrdaWarehouse::ClientNotes::Base.arel_table
    end

    def p_t
      GrdaWarehouse::Hud::Project.arel_table
    end

    def pc_t
      GrdaWarehouse::Hud::ProjectCoc.arel_table
    end

    def o_t
      GrdaWarehouse::Hud::Organization.arel_table
    end

    def i_t
      GrdaWarehouse::Hud::Inventory.arel_table
    end

    def af_t
      GrdaWarehouse::Hud::Affiliation.arel_table
    end

    def as_t
      GrdaWarehouse::Hud::Assessment.arel_table
    end

    def asq_t
      GrdaWarehouse::Hud::AssessmentQuestion.arel_table
    end

    def ev_t
      GrdaWarehouse::Hud::Event.arel_table
    end

    def ch_t
      GrdaWarehouse::Chronic.arel_table
    end

    def hc_t
      GrdaWarehouse::HudChronic.arel_table
    end

    def wc_t
      GrdaWarehouse::WarehouseClient.arel_table
    end

    def wcp_t
      GrdaWarehouse::WarehouseClientsProcessed.arel_table
    end

    def ib_t
      GrdaWarehouse::Hud::IncomeBenefit.arel_table
    end

    def d_t
      GrdaWarehouse::Hud::Disability.arel_table
    end

    def hdv_t
      GrdaWarehouse::Hud::HealthAndDv.arel_table
    end

    def f_t
      GrdaWarehouse::Hud::Funder.arel_table
    end

    def cls_t
      GrdaWarehouse::Hud::CurrentLivingSituation.arel_table
    end

    def enx_t
      GrdaWarehouse::EnrollmentExtra.arel_table
    end

    def hmis_form_t
      GrdaWarehouse::HmisForm.arel_table
    end

    def hmis_c_t
      GrdaWarehouse::HmisClient.arel_table
    end

    def c_client_t
      GrdaWarehouse::CohortClient.arel_table
    end

    def c_c_change_t
      GrdaWarehouse::CohortClientChange.arel_table
    end

    def yib_t
      GrdaWarehouse::YouthIntake::Base.arel_table
    end

    def vispdat_t
      GrdaWarehouse::Vispdat::Base.arel_table
    end

    def hp_t
      Health::Patient.arel_table
    end

    def hpr_t
      Health::PatientReferral.arel_table
    end

    def hapr_t
      Health::AgencyPatientReferral.arel_table
    end

    def hqa_t
      Health::QualifyingActivity.arel_table
    end

    def hpf_t
      Health::ParticipationForm.arel_table
    end

    def hpff_t
      Health::ParticipationFormFile.arel_table
    end

    def h_ssm_t
      Health::SelfSufficiencyMatrixForm.arel_table
    end

    def h_epic_ssm_t
      Health::EpicSsm.arel_table
    end

    def h_sdhcmn_t
      Health::SdhCaseManagementNote.arel_table
    end

    def h_ehs_t
      Health::EpicHousingStatus.arel_table
    end

    def h_ecn_t
      Health::EpicCaseNote.arel_table
    end

    def h_cha_t
      Health::ComprehensiveHealthAssessment.arel_table
    end

    def h_echa_t
      Health::EpicCha.arel_table
    end

    def h_rf_t
      Health::ReleaseForm.arel_table
    end

    def h_cp_t
      Health::Careplan.arel_table
    end

    def yib_t
      GrdaWarehouse::YouthIntake::Base.arel_table
    end

    def htca_t
      Health::Tracing::Case.arel_table
    end

    def htco_t
      Health::Tracing::Contact.arel_table
    end

    def h_sd_t
      Health::StatusDate.arel_table
    end

    def r_monthly_t
      Reporting::MonthlyReports::Base.arel_table
    end

    def hr_ri_t
      HudReports::ReportInstance.arel_table
    end
  end
end
