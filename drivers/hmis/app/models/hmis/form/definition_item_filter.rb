###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Dynamic filter form definition items based on item.rule.
class Hmis::Form::DefinitionItemFilter
  def self.perform(...)
    new(...).perform
  end

  attr_accessor :definition, :project, :project_funders, :active_date
  def initialize(definition:, project:, project_funders:, active_date:)
    self.definition = definition
    self.project = project
    self.project_funders = project_funders
    self.active_date = active_date
  end

  def perform
    eval_items([definition])[0]
  end

  protected

  # @param items [Array<Hash>]
  # @return items [Array<Hash>]
  def eval_items(items)
    # Comment in to disable rule filtering, to help with
    # testing all available form items
    # return items if Rails.env.development?

    items.filter do |item|
      has_hud_rule = item['rule'].present?
      has_custom_rule = item['custom_rule'].present?

      passed_eval = if has_hud_rule && has_custom_rule
        # Show if HUD rule passes or if Custom rule passes
        eval_rule(item['rule']) || eval_rule(item['custom_rule'])
      elsif has_hud_rule
        # Show if HUD rule passes
        eval_rule(item['rule'])
      elsif has_custom_rule
        # Show if custom rule passes
        eval_rule(item['custom_rule'])
      else
        # No rule specified, always show
        true
      end

      if passed_eval
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

  # @param rule [Hash]
  # @return [Boolean]
  def eval_rule(rule)
    # If there's no project, default to true.
    # This let's us have rules on the Client form, for example V1 Veteran Info,
    # that can be hidden when creating a Client in the context of a non-Veteran program,
    # but should always be shown when creating/editing a Client outside of a project context.
    return true if project.nil?

    operator = rule.fetch('operator')
    case operator
    when 'EQUAL'
      # { variable: 'projectType', operator: 'EQUAL', value: 1 }
      eval_var(rule.fetch('variable')) == eval_value(rule)
    when 'NOT_EQUAL'
      # { variable: 'projectType', operator: 'NOT_EQUAL', value: 1 }
      eval_var(rule.fetch('variable')) != eval_value(rule)
    when 'INCLUDE'
      # { variable: 'projectFunders', operator: 'INCLUDE', value: 1 }
      eval_var_multi(rule.fetch('variable')).include?(eval_value(rule))
    when 'NOT_INCLUDE'
      # { variable: 'projectFunders', operator: 'NOT_INCLUDE', value: 1 }
      eval_var_multi(rule.fetch('variable')).exclude?(eval_value(rule))
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
    when 'projectId'
      project&.project_id
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
      # ignore case for Funder.OtherFunder value which is a free text field
      project_funders.map(&:other_funder).compact.map(&:strip).map(&:downcase).compact_blank
    else
      raise "unknown variable for eval_var_multi #{key}"
    end
  end

  def eval_value(rule)
    variable = rule.fetch('variable')
    value = rule.fetch('value')

    case variable
    when 'projectOtherFunders'
      # ignore case for Funder.OtherFunder value which is a free text field
      value.strip.downcase
    else
      value
    end
  end
end
