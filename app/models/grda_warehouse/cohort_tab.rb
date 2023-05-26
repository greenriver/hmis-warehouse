###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    include ArelHelper

    # NOTE: rules live in a json blog of the following format
    # Each layer can only have a rule or a relation

    # { # Rule
    #   column: 'cohort_column_name',
    #   operator: '<, >, <>, ==', # pick one
    #   value: 'comparison value',
    # }

    # { # Relation
    #   operator: 'or',
    #   left: {
    #     column: 'cohort_column_name',
    #     operator: '<, >, <>, ==', # pick one
    #     value: 'comparison value',
    #   },
    #   right: {
    #     column: 'cohort_column_name',
    #     operator: '<, >, <>, ==', # pick one
    #     value: 'comparison value',
    #   }
    # }
    # { # Relation
    #   operator: 'and',
    #   left: { # Rule
    #     column: 'cohort_column_name',
    #     operator: '<, >, <>, ==', # pick one
    #     value: 'comparison value',
    #   },
    #   right: { # Relation
    #     operator: 'or',
    #     left: {
    #       column: 'cohort_column_name',
    #       operator: '<, >, <>, ==', # pick one
    #       value: 'comparison value',
    #     },
    #     right: {
    #       column: 'cohort_column_name',
    #       operator: '<, >, <>, ==', # pick one
    #       value: 'comparison value',
    #     }
    #   }
    # }

    def rule_query(composed_query, rule)
      return composed_query if rule.blank?

      if rule.key?('column')
        col = column(rule['column'])
        val = col.cast_value(rule['value'])
        composed_query = case rule['operator']
        when '<'
          col.arel_col.lt(val)
        when '>'
          col.arel_col.gt(val)
        when '=='
          col.arel_col.eq(val)
        when '<>'
          col.arel_col.not_eq(val)
        else
          raise 'Unknown Operator'
        end
      elsif rule.key?('left')
        # Do more
      end
      composed_query
    end

    def default_rules
    end

    def column(key)
      col = cohort_columns[key.to_sym]
      return col if col.present?

      raise 'Unknown Column'
    end

    def cohort_columns
      @cohort_columns ||= GrdaWarehouse::Cohort.available_columns.index_by(&:column)
    end
  end
end
