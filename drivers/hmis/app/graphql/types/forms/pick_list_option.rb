###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::PickListOption < Types::BaseObject
    field :code, String, 'Code for the option', null: false
    field :label, String, 'Label for the option', null: true
    field :secondary_label, String, 'Secondary label, such as project type or CoC code', null: true
    field :group_code, String, 'Code for group that option belongs to, if grouped', null: true
    field :group_label, String, 'Label for group that option belongs to, if grouped', null: true
    field :initial_selected, Boolean, 'Whether option is selected by default', null: true

    CODE_PATTERN = /^\(([0-9]*)\) /.freeze

    def self.options_for_type(pick_list_type, user:, relation_id: nil)
      relevant_state = ENV['RELEVANT_COC_STATE']

      case pick_list_type
      when 'COC'
        selected_project = Hmis::Hud::Project.viewable_by(user).find_by(id: relation_id) if relation_id.present?
        available_codes = if selected_project.present?
          selected_project.project_cocs.pluck(:CoCCode).uniq.map { |code| [code, ::HudUtility.cocs[code] || code] }
        else
          ::HudUtility.cocs_in_state(relevant_state)
        end

        available_codes.sort.map do |code, name|
          { code: code, label: "#{code} - #{name}", initial_selected: available_codes.length == 1 }
        end

      when 'STATE'
        state_options.map do |obj|
          {
            code: obj['abbreviation'],
            # label: "#{obj['abbreviation']} - #{obj['name']}",
            initial_selected: obj['abbreviation'] == relevant_state,
          }
        end

      when 'GEOCODE'
        geocodes_in_state(relevant_state).map do |obj|
          {
            code: obj['geocode'],
            label: "#{obj['geocode']} - #{obj['name']}",
          }
        end

      when 'PRIOR_LIVING_SITUATION'
        living_situation_options(as: :prior)

      when 'SERVICE_TYPE'
        Types::HmisSchema::Enums::ServiceTypeProvided.values.map do |key, enum|
          next if enum.value.is_a?(Integer) && enum.value.negative?

          record_type = enum.value.split(':').first
          record_type_key, record_type_enum = Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(record_type&.to_i)

          label = enum.description.gsub(CODE_PATTERN, '')
          sort_key = "#{record_type}:#{label}"

          [
            sort_key,
            {
              code: key,
              label: label,
              group_code: record_type_key,
              group_label: record_type_enum&.description&.gsub(CODE_PATTERN, ''),
            },
          ]
        end.
          compact.
          sort_by { |sort_key, _v| sort_key }.
          map(&:second)
      when 'SUB_TYPE_PROVIDED_3'
        sub_type_provided_options(Types::HmisSchema::Enums::Hud::SSVFSubType3, '144:3')

      when 'SUB_TYPE_PROVIDED_4'
        sub_type_provided_options(Types::HmisSchema::Enums::Hud::SSVFSubType4, '144:4')

      when 'SUB_TYPE_PROVIDED_5'
        sub_type_provided_options(Types::HmisSchema::Enums::Hud::SSVFSubType5, '144:5')

      when 'REFERRAL_OUTCOME'
        options_without_invalid_for_enum(Types::HmisSchema::Enums::Hud::PATHReferralOutcome)

      when 'CURRENT_LIVING_SITUATION'
        living_situation_options(as: :current)

      when 'DESTINATION'
        living_situation_options(as: :destination)

      when 'PROJECT'
        Hmis::Hud::Project.viewable_by(user).
          joins(:organization).
          sort_by_option(:organization_and_name).
          map do |project|
          {
            code: project.id,
            label: project.project_name,
            secondary_label: HudUtility.project_type_brief(project.project_type),
            group_label: project.organization.organization_name,
            group_code: project.organization.id,
          }
        end

      when 'ORGANIZATION'
        Hmis::Hud::Organization.viewable_by(user).
          sort_by_option(:name).
          map do |organization|
          {
            code: organization.id,
            label: organization.organization_name,
          }
        end
      when 'AVAILABLE_UNITS'
        inventory = Hmis::Hud::Inventory.find_by(id: relation_id) if relation_id.present?
        return [] unless inventory.present?

        inventory.units.map { |unit| { code: unit.id, label: unit.name } }
      end
    end

    def self.geocodes_in_state(state)
      Rails.cache.fetch(['GEOCODES', state], expires_in: 1.days) do
        JSON.parse(File.read("drivers/hmis/lib/pick_list_data/geocodes/geocodes-#{state}.json"))
      end
    end

    def self.state_options
      Rails.cache.fetch('STATE_OPTION_LIST', expires_in: 1.days) do
        JSON.parse(File.read('drivers/hmis/lib/pick_list_data/states.json'))
      end
    end

    def self.sub_type_provided_options(enum_type, type_provided_value)
      options_without_invalid_for_enum(enum_type).
        map do |item|
          parent_key, = Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value(type_provided_value)
          item.merge(code: "#{parent_key}__#{item[:code]}")
        end
    end

    def self.options_without_invalid_for_enum(enum_type)
      enum_type.values.reject { |_key, enum| enum.value.negative? }.map do |key, enum|
        {
          code: key,
          label: enum.description.gsub(CODE_PATTERN, ''),
        }
      end
    end

    def self.living_situation_options(as:)
      enum_value_definitions = Types::HmisSchema::Enums::Hud::LivingSituation.all_enum_value_definitions
      to_option = ->(group_code, group_label) {
        proc do |id|
          {
            code: enum_value_definitions.find { |v| v.value == id }.graphql_name,
            label: ::HudUtility.living_situation(id),
            group_code: group_code,
            group_label: group_label,
          }
        end
      }

      homeless = ::HudUtility.homeless_situations(as: as).map(&to_option.call('HOMELESS', 'Homeless'))
      institutional = ::HudUtility.institutional_situations(as: as).map(&to_option.call('INSTITUTIONAL', 'Institutional'))
      temporary = ::HudUtility.temporary_and_permanent_housing_situations(as: as).map(&to_option.call('TEMPORARY_PERMANENT_OTHER', 'Temporary or Permanent'))
      missing_reasons = ::HudUtility.other_situations(as: as).map(&to_option.call('MISSING', 'Other'))

      homeless + institutional + temporary + missing_reasons
    end
  end
end
