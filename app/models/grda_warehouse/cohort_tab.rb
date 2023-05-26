###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    include ArelHelper

    def rule_query(composed_query, rule)
      return composed_query if rule.blank?

      composed_query = if rule.key?('column') # Base case: no children, return the arel
        col = column(rule['column'])
        val = col.cast_value(rule['value'])
        case rule['operator']
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
        case rule['operator']
        when 'and'
          rule_query(composed_query, rule['left']).and(rule_query(composed_query, rule['right']))
        when 'or'
          rule_query(composed_query, rule['left']).or(rule_query(composed_query, rule['right']))
        else
          raise 'Unknown Operator'
        end
      end
      composed_query
    end

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
    def default_rules
      {
        active: {
          'operator' => 'and',
          'left' => {
            'operator' => 'and',
            'left' => {
              'column' => 'housed_date',
              'operator' => '==',
              'value' => nil,
            },
            'right' => {
              'column' => 'active',
              'operator' => '==',
              'value' => true,
            },
          },
          'right' => {
            'operator' => 'and',
            'left' => {
              'column' => 'destination',
              'operator' => '==',
              'value' => nil,
            },
            'right' => {
              'column' => 'ineligible',
              'operator' => '==',
              'value' => nil,
            },
          },
        },
        housed: {
          'operator' => 'and',
          'left' => {
            'column' => 'housed_date',
            'operator' => '<>',
            'value' => nil,
          },
          'right' => {
            'column' => 'destination',
            'operator' => '<>',
            'value' => nil,
          },
        },
        ineligible: {
          'operator' => 'and',
          'left' => {
            'column' => 'ineligible',
            'operator' => '==',
            'value' => true,
          },
          'right' => {
            'operator' => 'or',
            'left' => {
              'column' => 'housed_date',
              'operator' => '==',
              'value' => nil,
            },
            'right' => {
              'column' => 'destination',
              'operator' => '==',
              'value' => nil,
            },
          },
        },
        inactive: {
          'column' => 'active',
          'operator' => '==',
          'value' => false,
        },
        # NOTE: deleted scope is left off since it requires overriding the default scop
      }
    end

    def column(key)
      col = cohort_columns[key.to_sym]
      return col if col.present?

      raise 'Unknown Column'
    end

    def cohort_columns
      @cohort_columns ||= GrdaWarehouse::Cohort.available_columns.select(&:available_for_rules?).index_by(&:column)
    end
  end
end
