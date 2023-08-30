# frozen_string_literal: true

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::FormDefinition < Types::BaseObject
    description 'FormDefinition'
    field :id, ID, null: false
    field :cache_key, ID, null: true
    field :role, Types::Forms::Enums::FormRole, null: false
    field :definition, Forms::FormDefinitionJson, null: false

    # Filtering is implemented within this resolver rather than a separate concern. This
    # gives us convenient to access the lazy batch loader for records (funder, orgs) that
    # we might need to apply filter. Probably the filtering should get moved to it's own
    # class down the road
    def definition
      eval_items([object.definition])[0]
    end

    def cache_key
      [object.id, project&.id, active_date].join('|')
    end

    protected

    # @param items [Array<Hash>]
    # @return items [Array<Hash>]
    def eval_items(items)
      # Comment in to disable rule filtering, to help with
      # testing all available form items
      # return items if Rails.env.development?

      items.filter do |item|
        if eval_rule(item['rule'])
          if item['item']
            # filter children
            item['item'] = eval_items(item['item'])
            # if all children are filtered out, exclude the parent
            item['item'].any?
          else
            true
          end
        else
          false
        end
      end
    end

    # @param rule [nil, Array, Hash]
    # @return [Boolean]
    def eval_rule(rule)
      # if there's no rule, default to true
      return true if rule.nil?

      operator = rule.fetch('operator')
      case operator
      when 'EQUAL'
        # { variable: 'projectType', operator: 'EQUAL', value: 1 }
        eval_var(rule.fetch('variable')) == rule.fetch('value')
      when 'NOT_EQUAL'
        # { variable: 'projectType', operator: 'NOT_EQUAL', value: 1 }
        eval_var(rule.fetch('variable')) != rule.fetch('value')
      when 'INCLUDE'
        # { variable: 'projectFunders', operator: 'INCLUDE', value: 1 }
        eval_var_multi(rule.fetch('variable')).include?(rule.fetch('value'))
      when 'NOT_INCLUDE'
        # { variable: 'projectFunders', operator: 'NOT_INCLUDE', value: 1 }
        eval_var_multi(rule.fetch('variable')).exclude?(rule.fetch('value'))
      when 'ANY'
        # { operator: 'ANY', parts: [ ... ] },
        rule.fetch('parts').any? { |r| eval_rule(r) }
      when 'ALL'
        # { operator: 'ALL', parts: [ ... ] },
        rule.fetch('parts').all? { |r| eval_rule(r) }
      else
        raise "operator not supported: #{operator}"
      end
    end

    # @param key [String]
    # @return [String, Integer, nil]
    def eval_var(key)
      case key
      when 'projectType'
        project&.project_type
      else
        raise "unknown variable for eval_var #{key}"
      end
    end

    # @param key [String]
    # @return [Array<String, Integer>]
    def eval_var_multi(key)
      case key
      when 'projectFunders'
        project_funders.map { |f| f.funder&.to_i }.compact_blank
      when 'projectFunderComponents'
        project_funders.map { |f| HudUtility2024.funder_component(f.funder&.to_i) }.compact_blank
      when 'projectOtherFunders'
        project_funders.map(&:other_funder).compact_blank
      else
        raise "unknown variable for eval_var_multi #{key}"
      end
    end

    def project
      object.filter_context&.fetch(:project, nil)
    end

    # Context can optionally include an "active date", so that funder-based rules
    # only consider funders that are active on the specified date.
    def active_date
      object.filter_context&.fetch(:active_date, nil) || Date.current
    end

    def project_funders
      return [] unless project.present?

      funders = load_ar_association(project, :funders)
      funders.to_a.select { |f| f.active_on?(active_date) }
    end
  end
end
