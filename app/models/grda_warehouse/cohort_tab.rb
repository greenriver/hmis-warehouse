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

    def show_for?(user)
      return true if permissions.empty?

      permissions.map do |perm|
        user.send("#{perm}?")
      end.any?
    end

    def cohort_client_filter(user) # rubocop:disable Lint/UnusedMethodArgument
      # TODO: inactive and deleted need user permission scopes
      # def inactive_scope user
      # return @client_search_scope.none unless user.can_view_inactive_cohort_clients? || user.can_manage_inactive_cohort_clients?
      # def show_inactive user
      # return false unless user.can_view_inactive_cohort_clients? || user.can_manage_inactive_cohort_clients?
      # def deleted_scope(user)
      # return @client_search_scope.none unless can_see_deleted_cohort_clients?(user)
      rule_query(nil, rules)
    end

    def to_sql
      rule_query(nil, rules)&.to_sql
    end

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
      [
        {
          name: 'Active Clients',
          order: 0,
          permissions: [],
          rules: {
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
        },
        {
          name: 'Housed',
          order: 1,
          permissions: [],
          rules: {
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
        },
        {
          name: 'Ineligible',
          order: 2,
          permissions: [],
          rules: {
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
        },
        {
          name: 'Inactive',
          order: 3,
          permissions: [
            :can_view_inactive_cohort_clients,
            :can_manage_inactive_cohort_clients,
          ],
          rules: {
            'column' => 'active',
            'operator' => '==',
            'value' => false,
          },
        },
        {
          name: 'Removed Clients',
          order: 4,
          base_scope: :only_deleted,
          permissions: [
            :can_view_deleted_cohort_clients,
            :can_add_cohort_clients,
          ],
          rules: {},
        },
      ]
    end
  end
end
