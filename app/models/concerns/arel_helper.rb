# provides less verbose versions of stuff that's useful for working with arel
# these are all two letters both for maximum brevity and because this makes them more includable -- they are unlikely to be stomped on by other methods or functions
module ArelHelper
  extend ActiveSupport::Concern

  # give these methods to instances
  included do

    def qt(value)
      self.class.qt value
    end

    def nf(*args)
      self.class.nf *args
    end

    def unionize(*args)
      self.class.unionize *args
    end

    def add_alias( aka, table )
      self.class.add_alias aka, table
    end

    # create the COALESCE named function
    def cl(*args)
      nf 'COALESCE', args
    end

    # create the CONCAT named function
    def ct(*args)
      nf 'CONCAT', args
    end

    def lit(str)
      self.class.lit str
    end

    def acase(conditions, elsewise: nil)
      self.class.acase conditions, elsewise: elsewise
    end

    def cast(exp, as)
      self.class.cast exp, as
    end

    def datediff(*args)
      self.class.datediff *args
    end

    def datepart(*args)
      self.class.datepart *args
    end

    def checksum(*args)
      self.class.checksum *args
    end
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
      tables = tables.map{ |t| t.respond_to?(:ast) ? t.ast : t }
      while tables.many?
        tables = tables.in_groups_of(2).map do |t1, t2|
          if t2
            Arel::Nodes::Union.new t1, t2
          else   # we have an odd number of items
            t1
          end
        end
      end
      tables.first
    end

    # attempt to add an alias to a table-y thing
    def add_alias( aka, table )   # alias is first because it is probably the lighter argument
      if table.respond_to?(:as)
        table.as(aka)
      else
        Arel::Nodes::TableAlias.new table, aka
      end
    end

    # create a named function
    #   nf 'NAME', [ arg1, arg2, arg3 ], 'alias'
    def nf( name, args=[], aka=nil )
      raise 'args must be an Array' unless args.is_a?(Array)
      Arel::Nodes::NamedFunction.new name, args.map{ |v| qt v }, aka
    end

    # bonk out a SQL literal
    def lit(str)
      Arel::Nodes::SqlLiteral.new str
    end

    # a little syntactic sugar to make a case statement
    def acase(conditions, elsewise: nil)
      stmt = conditions.map do |c,v|
        "WHEN (#{qt(c).to_sql}) THEN (#{qt(v).to_sql})"
      end.join ' '
      if elsewise.present?
        stmt += " ELSE (#{qt(elsewise).to_sql})"
      end
      lit "CASE #{stmt} END"
    end

    # to translate between SQL Server DATEDIFF and Postgresql DATE_PART, and eventually, if need be, the equivalent mechanisms of
    # other DBMS's
    def datediff(engine, type, d1, d2)
      case engine.connection.adapter_name
      when 'PostgreSQL'
        d1, d2 = [ d1, d2 ].map{ |d| datepart engine, type, d }
        Arel::Nodes::Subtraction.new d1, d2
      when 'SQLServer'
        nf 'DATEDIFF', [ lit(type), d1, d2 ]
      else
        raise NotImplementedError
      end
    end

    # to translate between SQL Server DATEPART and Postgresql DATE_PART, and eventually, if need be, the equivalent mechanisms of
    # other DBMS's
    def datepart(engine, type, d)
      case engine.connection.adapter_name
      when 'PostgreSQL'
        d = lit "#{Arel::Nodes::Quoted.new(d).to_sql}::date" if d.is_a? String
        nf 'DATE_PART', [ type, d ]
      when 'SQLServer'
        nf 'DATEPART', [ lit(type), d ]
      else
        raise NotImplementedError
      end
    end

    # to translate between SQL Server CHECKSUM and Postgresql MD5
    def checksum(engine, fields)
      case engine.connection.adapter_name
      when 'PostgreSQL'
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



    # Some shortcuts for arel tables
    def sh_t
      GrdaWarehouse::ServiceHistory.arel_table
    end
    def e_t
      GrdaWarehouse::Hud::Enrollment.arel_table
    end
    def ds_t
      GrdaWarehouse::DataSource.arel_table
    end
    def c_t
      GrdaWarehouse::Hud::Client.arel_table
    end
    def p_t
      GrdaWarehouse::Hud::Project.arel_table
    end
  end
end