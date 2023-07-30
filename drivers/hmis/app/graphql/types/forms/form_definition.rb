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
    field :role, Types::Forms::Enums::FormRole, null: false
    field :definition, Forms::FormDefinitionJson, null: false

    # Filtering is implemented within this resolver rather than a separate concern. This
    # gives us convenient to access the lazy batch loader for records (funder, orgs) that
    # we might need to apply filter. Probably the filtering should get moved to it's own
    # class down the road
    def definition
      # the col is jsonb... somehow we get a string here?
      eval_items([object.definition])[0]
    end

    protected

    # @param items [Array<Hash>]
    # @return items [Array<Hash>]
    def eval_items(items)
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
        # { variable: 'projectType', operator: 'EQUAL', value: '1' }
        eval_var(rule.fetch('variable')) == rule.fetch('value')
      when 'INCLUDE'
        # { variable: 'projectFunderIds', operator: 'INCLUDE', value: '1' }
        eval_var_multi(rule.fetch('variable')).include?(rule.fetch('value'))
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
    # @return String
    def eval_var(key)
      case key
      when 'projectType'
        project&.project_type&.to_s
      else
        raise "unknown variable #{key}"
      end
    end

    # @param key [String]
    # @return [String]
    def eval_var_multi(key)
      case key
      when 'projectFunderIds'
        project_funders.map(&:funder_id)
      when 'projectOtherFunders'
        project_funders.map(&:other_funder)
      else
        raise "unknown variable #{key}"
      end
    end

    def project_funders
      project ? load_ar_association(project, :funders) : []
    end

    def project
      object.filter_context&.fetch(:project, nil)
    end
  end
end
