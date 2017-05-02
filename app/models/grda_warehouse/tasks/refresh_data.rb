require 'csv'

module GrdaWarehouse::Tasks

  # fetches a sample of destination clients, all their sources, the complete graph of entities
  # connected to these clients via belongs-to associations, plus all connected entities for models
  # referred to in GrdaWarehouse::Hud#models_by_hud_filename
  # it then creates a source subdirectory for each data source referred to by these objects and
  # dumps into that subdirectory csv files for all such objects
  class RefreshData

    attr_reader :dir, :logger

    class BogusLogger
      def info(msg)
        puts msg
      end

      def error(msg)
        puts "[ERROR] #{msg}"
      end

      def warn(msg)
        puts "[WARN] #{msg}"
      end
    end

    def initialize( dir: 'tmp/testing', logger: BogusLogger.new )
      @dir    = dir
      @logger = logger
    end

    def data_sources_file
      GrdaWarehouse::Tasks::TestData::DATA_SOURCES
    end

    def touched_tables
      @table_definitions.values.map{ |h| h[:model] }.map(&:constantize)
    end

    def run!
      collect_table_definitions

      # make sure all the required tables exist in the testing database
      verify_table data_sources_file
      @table_definitions.keys.select{ |k| Symbol === k }.each do |tn|
        verify_table tn
      end
      verify_table Nickname.name
      verify_table UniqueName.name
      touched_tables.each do |model|
        model.reset_column_information
        logger.info "deleting all rows from #{model.table_name}"
        model.delete_all
      end

      # instantiate the data sources used
      data_source_ids = []
      file = File.open "#{dir}/#{data_sources_file}", 'r'
      headers = nil
      file.each_line do |line|
        CSV.parse(line) do |row|
          if headers.nil?
            headers = row
          else
            attributes = headers.zip(row).to_h.symbolize_keys
            id = attributes.delete(:id).to_i
            data_source_ids << id
            source = sources.where( id: id ).first_or_initialize
            source.assign_attributes **attributes
            source.save!
          end
        end
      end

      # populate all the HUD tables
      if data_source_ids.empty?
        logger.info "no data sources found"
      else
        data_source_ids.each do |id|
          subdirectory = "#{dir}/source-#{id}"
          importer = Importers::Samba.new id, sources, directory: { id => subdirectory }
          importer.run!
        end
      end
      logger.info 'done'
    end

    def sources
      GrdaWarehouse::DataSource
    end

    def file_map
      @file_map ||= GrdaWarehouse::Hud.models_by_hud_filename.to_a.map(&:reverse).to_h
    end

    def table_info(table)
      ( @table_info ||= {} )[table.name] ||= begin
        logger.info "getting schema for #{table.name}"
        table.reset_column_information
        {
          name:    table.table_name.to_sym,
          model:   table.name,
          columns: table.columns.reject{ |c| c.name == 'id' },
          indexes: table.connection.indexes(table.table_name)
        }
      end
    end

    def collect_table_definitions
      logger.info "connecting to development GRDA warehouse database to collect table definitions..."
      GrdaWarehouseBase.establish_connection(:development_grda_warehouse)
      ActiveRecord::Base.establish_connection(:development)
      extensions = ActiveRecord::Base.connection.extensions
      Rails.application.eager_load!
      @table_definitions = GrdaWarehouse::Hud.models_by_hud_filename.map do |file, table|
        [ file, table_info(table) ]
      end
      @table_definitions << [ Nickname.name.to_sym, table_info(Nickname) ]
      @table_definitions << [ UniqueName.name.to_sym, table_info(UniqueName) ]
      @table_definitions << [ SimilarityMetric::Base.name.to_sym, table_info(SimilarityMetric::Base) ]
      GrdaWarehouseBase.descendants.reject(&:abstract_class?).each do |table|
        @table_definitions << [ table.name.to_sym, table_info(table) ]
      end
      @table_definitions = @table_definitions.to_h
      logger.info "connecting to testing database..."
      GrdaWarehouseBase.establish_connection(:test)
      ActiveRecord::Base.establish_connection(:test)
      ( extensions - ActiveRecord::Base.connection.extensions ).each do |x|
        ActiveRecord::Base.connection.enable_extension x
      end
    end

    # creates tables as needed
    # note, this assumes static schemas, which is probably incorrect
    def verify_table(file)
      info = @table_definitions[file]
      return false if info.nil?
      name, model, columns, indexes = info.slice( :name, :model, :columns, :indexes ).values
      logger.info "verifying #{name}..."
      model = model.constantize
      model.reset_column_information
      conn = GrdaWarehouseBase.connection
      unless good_table? conn, name, model, columns, indexes
        logger.info "creating table #{name} in test database..."
        conn.create_table name
        columns.each do |col|
          n, type, atts = column_attributes(col)
          type = munge_type type, conn
          conn.add_column name, n, type, **atts
        end
        indexes.each do |index|
          conn.add_index name, index.columns, name: index_name(index.name), unique: !!index.unique
        end
      end
      true
    end

    def column_attributes(col)
      atts = case col.sql_type
      when "nvarchar(max)"
        {}
      when /^n?varchar\((\d+)\)/
        { limit: Regexp.last_match[1].to_i }
      when /decimal\((\d+),(\d+)\)/
        p, s = Regexp.last_match[1..2]
        { precision: p.to_i, scale: s.to_i }
      else
        {}
      end
      [ col.name, col.type, **atts, null: col.null, default: col.default ]
    end

    # does the existing test table have an identical schema to the staging table?
    def good_table? connection, name, model, columns, indexes
      return false unless connection.table_exists? name
      return true if good_schema? connection, name, model, columns, indexes
      logger.info "must rebuild table #{name} for #{model.name}"
      indexes.each do |i|
        next unless connection.index_exists?( name, i.columns, unique: !!i.unique )
        connection.remove_index name, name: index_name(i.name)
      end
      connection.drop_table name
      false
    end

    # to make index names play nice with postgres
    def index_name(name)
      if name.length > 63
        # this turns "index_EmploymentEducation_on_data_source_id_and_PersonalID", for example, into "index_EE_on_data_s_id_and_PID"
        logger.warn "must shorten index name '#{name}'"
        name = name.gsub(/[a-z]{6,}/i){ |m| m[0] + m[1..-1].gsub( /[a-z]/, '' ) }[0...63]
        logger.warn "new name: '#{name}'"
        name
      else
        name
      end
    end

    def type_match(t1, t2, connection)
      t1, t2 = [ t1, t2 ].map{ |t| munge_type t, connection }
      t1 == t2 || [ t1, t1 ].all?{ |t| t == :string || t == :varchar }
    end

    # handle types which don't exist for the DBMS appropriately
    def munge_type(t, connection)
      case t
      when :smalldatetime
        if connection.adapter_name == 'PostgreSQL'
          :datetime
        else
          t
        end
      else
        t
      end
    end

    def good_schema? connection, name, model, columns, indexes
      columns.each do |c|
        n, type, atts = column_attributes(c)
        test = model.columns.any? do |c|   # column_exists? seems to have problems
          c.name == n &&
          type_match( c.type, type, connection ) &&
          !!c.null == atts[:null] &&
          c.default == atts[:default]
        end
        # byebug unless test
        return false unless test
      end
      indexes.each do |i|
        return false unless connection.indexes(name).any? do |o|   # index_exists? seems not to work
          index_name(o.name) == index_name(i.name) && o.columns == i.columns && !!o.unique == !!i.unique
        end
      end
      true
    end
  end
end
