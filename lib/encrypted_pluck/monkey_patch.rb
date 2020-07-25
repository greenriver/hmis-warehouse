# frozen_string_literal: true

ActiveRecord::Calculations

module ActiveRecord
  module Calculations
    # Use #pluck as a shortcut to select one or more attributes without
    # loading a bunch of records just to grab the attributes you want.
    #
    #   Person.pluck(:name)
    #
    # instead of
    #
    #   Person.all.map(&:name)
    #
    # Pluck returns an Array of attribute values type-casted to match
    # the plucked column names, if they can be deduced. Plucking an SQL fragment
    # returns String values by default.
    #
    #   Person.pluck(:name)
    #   # SELECT people.name FROM people
    #   # => ['David', 'Jeremy', 'Jose']
    #
    #   Person.pluck(:id, :name)
    #   # SELECT people.id, people.name FROM people
    #   # => [[1, 'David'], [2, 'Jeremy'], [3, 'Jose']]
    #
    #   Person.distinct.pluck(:role)
    #   # SELECT DISTINCT role FROM people
    #   # => ['admin', 'member', 'guest']
    #
    #   Person.where(age: 21).limit(5).pluck(:id)
    #   # SELECT people.id FROM people WHERE people.age = 21 LIMIT 5
    #   # => [2, 3]
    #
    #   Person.pluck('DATEDIFF(updated_at, created_at)')
    #   # SELECT DATEDIFF(updated_at, created_at) FROM people
    #   # => ['0', '27761', '173']
    #
    # See also #ids.
    #
    attr_accessor :plucker

    def pluck(*column_names)
      if loaded? && (column_names.map(&:to_s) - @klass.attribute_names - @klass.attribute_aliases.keys).empty?
        new_column_names = get_pii_column_names(column_names, relation: spawn, simple: true)
        return put_pii_values(records.pluck(*new_column_names))
      end

      if has_include?(column_names.first)
        relation = apply_join_dependency
        new_column_names = get_pii_column_names(column_names, relation: relation)
        put_pii_values(relation.pluck(*new_column_names))
      else
        klass.enforce_raw_sql_whitelist(column_names)
        relation = spawn
        relation.select_values = get_pii_column_names(column_names, relation: relation)
        result = skip_query_cache_if_necessary { klass.connection.select_all(relation.arel, nil) }
        put_pii_values(result.cast_values(klass.attribute_types))
      end
    end

    def get_pii_column_names(column_names, relation:, simple: true)
      self.plucker = Encryption::Pluck.new(column_names, context: self, relation: relation, simple: simple)
      self.plucker.transformed_columns
    end

    def put_pii_values(records)
      self.plucker.transformed_values(records)
    end
  end
end
