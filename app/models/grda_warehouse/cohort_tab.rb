###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CohortTab < GrdaWarehouseBase
    include ArelHelper
    acts_as_paranoid

    belongs_to :cohort

    def rule_query(composed_query, rule)
      return composed_query if rule.blank?

      return prepare_rule(rule) if rule.key?('column') # Base case: no children, return the arel

      composed_query = prepare_rule_combination(composed_query, rule)
      composed_query
    end

    private def prepare_rule(rule)
      col = column(rule['column'])
      val = if rule['value'].nil?
        nil
      else
        col.cast_value(rule['value'])
      end
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
        raise "Unknown Operator #{rule['operator']}"
      end
    end

    private def prepare_rule_combination(composed_query, rule)
      case rule['operator']
      when 'and'
        rule_query(composed_query, rule['left']).and(rule_query(composed_query, rule['right']))
      when 'or'
        rule_query(composed_query, rule['left']).or(rule_query(composed_query, rule['right']))
      else
        raise "Unknown Operator #{rule['operator']}"
      end
    end

    private def column(key)
      col = cohort_columns[key.to_s]
      return col if col.present?

      raise "Unknown Column #{key}"
    end

    private def cohort_columns
      @cohort_columns ||= GrdaWarehouse::Cohort.available_columns.select(&:available_for_rules?).index_by { |cc| cc.column.to_s }
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
    def self.default_rules
      {
        'Active Clients' => {
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
              'operator' => 'or',
              'left' => {
                'column' => 'destination',
                'operator' => '==',
                'value' => nil,
              },
              'right' => {
                'column' => 'destination',
                'operator' => '==',
                'value' => '',
              },
            },
            'right' => {
              'operator' => 'or',
              'left' => {
                'column' => 'ineligible',
                'operator' => '==',
                'value' => nil,
              },
              'right' => {
                'column' => 'ineligible',
                'operator' => '==',
                'value' => false,
              },
            },
          },
        },
        'Housed' => {
          'operator' => 'and',
          'left' => {
            'column' => 'housed_date',
            'operator' => '<>',
            'value' => nil,
          },
          'right' => {
            'operator' => 'or',
            'left' => {
              'column' => 'destination',
              'operator' => '<>',
              'value' => nil,
            },
            'right' => {
              'column' => 'destination',
              'operator' => '<>',
              'value' => '',
            },
          },
        },
        'Ineligible' => {
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
              'operator' => 'or',
              'left' => {
                'column' => 'destination',
                'operator' => '==',
                'value' => nil,
              },
              'right' => {
                'column' => 'destination',
                'operator' => '==',
                'value' => '',
              },
            },
          },
        },
        'Inactive' => {
          'column' => 'active',
          'operator' => '==',
          'value' => false,
        },
        # NOTE: deleted scope is left off since it requires overriding the default scop
      }
    end
  end
end
