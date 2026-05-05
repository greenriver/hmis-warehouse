###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module FormHelpers
  def build_minimum_values(definition, assessment_date: nil, values: {}, hud_values: {})
    assessment_date ||= Date.yesterday.strftime('%Y-%m-%d')

    date_item = definition.assessment_date_item
    date_field = date_item.mapping.field_name
    date_field = "Exit.#{date_field}" if definition.exit?
    date_field = "Enrollment.#{date_field}" if definition.intake?

    values = { date_item.link_id => assessment_date, **values.stringify_keys }
    hud_values = { date_field => assessment_date, **hud_values.stringify_keys }
    hud_values['Exit.destination'] = 'SAFE_HAVEN' if definition.exit?

    {
      values: values,
      hud_values: hud_values,
    }
  end

  def add_item_to_definition(definition, item)
    definition.definition['item'] << item
    definition.save!
    definition
  end

  def hud_values_to_values_by_link_id(hud_values)
    values_by_link_id = {}

    # hack: convert 'Client.firstName'=>'firstName' because we know the field names are not duplicated
    # across record types in the mocks..
    hud_values_keys_by_fname = hud_values.transform_keys { |k| k.split('.').last }

    # generate the value map {LinkID=>value} containing each mocked value
    definition.link_id_item_hash.each do |link_id, item|
      next unless item.mapping&.field_name.present?
      next unless hud_values_keys_by_fname.key?(item.mapping.field_name)

      value = hud_values_keys_by_fname[item.mapping.field_name]
      values_by_link_id[link_id] = value unless value == '_HIDDEN'
    end

    values_by_link_id
  end
end
