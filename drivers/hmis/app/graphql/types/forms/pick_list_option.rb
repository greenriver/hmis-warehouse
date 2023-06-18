###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::PickListOption < Types::BaseObject
    include Hmis::Concerns::HmisArelHelper

    field :code, String, 'Code for the option', null: false
    field :label, String, 'Label for the option', null: true
    field :secondary_label, String, 'Secondary label, such as project type or CoC code', null: true
    field :group_code, String, 'Code for group that option belongs to, if grouped', null: true
    field :group_label, String, 'Label for group that option belongs to, if grouped', null: true
    field :initial_selected, Boolean, 'Whether option is selected by default', null: true

    CODE_PATTERN = /^\(([0-9]*)\) /

    def self.options_for_type(pick_list_type, user:, relation_id: nil)
      # NOTE: relation_id is not necessarily a project id, that depends on the pick list type
      project = Hmis::Hud::Project.find_by(id: relation_id) if relation_id.present?

      case pick_list_type
      when 'COC'
        coc_picklist(project)
      when 'STATE'
        state_picklist
      when 'GEOCODE'
        geocodes_picklist
      when 'PRIOR_LIVING_SITUATION'
        living_situation_picklist(as: :prior)
      when 'SERVICE_TYPE'
        service_type_picklist
      when 'AVAILABLE_SERVICE_TYPES'
        available_service_types_picklist(project)
      when 'SUB_TYPE_PROVIDED_3'
        sub_type_provided_picklist(Types::HmisSchema::Enums::Hud::SSVFSubType3, '144:3')
      when 'SUB_TYPE_PROVIDED_4'
        sub_type_provided_picklist(Types::HmisSchema::Enums::Hud::SSVFSubType4, '144:4')
      when 'SUB_TYPE_PROVIDED_5'
        sub_type_provided_picklist(Types::HmisSchema::Enums::Hud::SSVFSubType5, '144:5')
      when 'CURRENT_LIVING_SITUATION'
        living_situation_picklist(as: :current)
      when 'DESTINATION'
        living_situation_picklist(as: :destination)
      when 'PROJECT'
        Hmis::Hud::Project.viewable_by(user).
          joins(:organization).
          sort_by_option(:organization_and_name).
          map(&:to_pick_list_option)
      when 'ENROLLABLE_PROJECTS'
        Hmis::Hud::Project.viewable_by(user).with_access(user, :can_enroll_clients).
          joins(:organization).
          sort_by_option(:organization_and_name).
          map(&:to_pick_list_option)
      when 'ORGANIZATION'
        Hmis::Hud::Organization.viewable_by(user).
          sort_by_option(:name).
          map(&:to_pick_list_option)

      when 'UNIT_TYPES'
        # If no project was specified, return all unit types
        all_unit_types = Hmis::UnitType.order(:description, :id)
        return all_unit_types.map(&:to_pick_list_option) unless relation_id.present?
        return [] unless project.present? # relation id specified but project not found

        unit_types_for_project(project, available_only: false)
      when 'AVAILABLE_UNIT_TYPES'
        return [] unless project.present?

        unit_types_for_project(project, available_only: true)
      when 'UNITS'
        return [] unless project.present?

        project.units.order(:name, :id).map(&:to_pick_list_option)
      when 'AVAILABLE_UNITS'
        return [] unless project.present?

        project.units.unoccupied.order(:name, :id).map(&:to_pick_list_option)
      when 'AVAILABLE_FILE_TYPES'
        file_tag_picklist
      when 'CLIENT_ENROLLMENTS'
        client = Hmis::Hud::Client.viewable_by(user).find_by(id: relation_id)
        return [] unless client.present?

        client.enrollments.sort_by_option(:most_recent).map do |enrollment|
          {
            code: enrollment.id,
            label: "#{enrollment.project.project_name} (#{[enrollment.entry_date.strftime('%m/%d/%Y'), enrollment.exit_date&.strftime('%m/%d/%Y') || 'ongoing'].join(' - ')})",
          }
        end

      when 'ASSIGNED_REFERRAL_POSTING_STATUSES'
        HmisExternalApis::AcHmis::ReferralPosting::ASSIGNED_STATUSES.map do |status|
          {
            code: status,
            label: status.gsub(/_status\z/, '').humanize.titleize,
          }
        end
      when 'DENIED_PENDING_REFERRAL_POSTING_STATUSES'
        label_map = {
          'assigned_status' => 'Send Back',
          'denied_status' => 'Approve Denial',
        }
        HmisExternalApis::AcHmis::ReferralPosting::DENIAL_STATUSES.map do |status|
          {
            code: status,
            label: label_map.fetch(status),
          }
        end
      when 'REFERRAL_RESULT_TYPES'
        # ::HudLists.referral_result_map
        [
          { code: Types::HmisSchema::Enums::Hud::ReferralResult.key_for(2), label: 'Client Rejected' },
          { code: Types::HmisSchema::Enums::Hud::ReferralResult.key_for(3), label: 'Provider Rejected' },
        ]
      end
    end

    def self.unit_types_for_project(project, available_only: false)
      units = project.units
      units = units.unoccupied if available_only

      # Hash { unit type id => num unoccupied }
      unit_type_to_availability = units.group(:unit_type_id).count

      Hmis::UnitType.order(:description, :id).
        where(id: unit_type_to_availability.keys).
        map(&:to_pick_list_option).
        map do |option|
          num_left = unit_type_to_availability[option[:code].to_i]
          option[:secondary_label] = "#{num_left} available"
          option
        end
    end

    def self.coc_picklist(selected_project)
      available_codes = if selected_project.present?
        selected_project.project_cocs.pluck(:CoCCode).uniq.map { |code| [code, ::HudUtility.cocs[code] || code] }
      else
        ::HudUtility.cocs_in_state(ENV['RELEVANT_COC_STATE'])
      end

      available_codes.sort.map do |code, name|
        { code: code, label: "#{code} - #{name}", initial_selected: available_codes.length == 1 }
      end
    end

    def self.geocodes_picklist
      state = ENV['RELEVANT_COC_STATE']
      Rails.cache.fetch(['GEOCODES', state], expires_in: 1.days) do
        JSON.parse(File.read("drivers/hmis/lib/pick_list_data/geocodes/geocodes-#{state}.json"))
      end.map do |obj|
        {
          code: obj['geocode'],
          label: "#{obj['geocode']} - #{obj['name']}",
        }
      end
    end

    def self.state_picklist
      Rails.cache.fetch('STATE_OPTION_LIST', expires_in: 1.days) do
        JSON.parse(File.read('drivers/hmis/lib/pick_list_data/states.json'))
      end.map do |obj|
        {
          code: obj['abbreviation'],
          # label: "#{obj['abbreviation']} - #{obj['name']}",
          initial_selected: obj['abbreviation'] == ENV['RELEVANT_COC_STATE'],
        }
      end
    end

    def self.available_service_types_picklist(project)
      return [] unless project.present?

      # Find services that have form definitions specified in this project
      ids = Hmis::Form::Instance.for_services.
        for_project_through_entities(project).
        joins(:definition).
        where(fd_t[:role].eq(:SERVICE)).
        pluck(:custom_service_type_id, :custom_service_category_id)

      options = Hmis::Hud::CustomServiceType.where(cst_t[:id].in(ids.map(&:first)).
          or(cst_t[:custom_service_category_id].in(ids.map(&:last)))).
        preload(:custom_service_category).to_a.
        map(&:to_pick_list_option).
        sort_by { |obj| obj[:group_label] + obj[:label] }

      options[0][:initial_selected] = true if options.size == 1

      options
    end

    def self.service_type_picklist
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
    end

    def self.sub_type_provided_picklist(enum_type, type_provided_value)
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

    def self.living_situation_picklist(as:)
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
      missing_reasons = ::HudUtility.other_situations(as: as).excluding(99).map(&to_option.call('MISSING', 'Other'))

      homeless + institutional + temporary + missing_reasons
    end

    def self.file_tag_picklist
      Hmis::File.all_available_tags.map do |tag|
        {
          code: tag.id,
          label: tag.name,
          group_code: tag.group,
          group_label: tag.group,
          secondary_label: tag.included_info&.strip&.present? ? "(includes: #{tag.included_info})" : nil,
        }
      end.
        compact.
        sort_by { |obj| [obj[:group_label] + obj[:label]].join(' ') }
    end
  end
end
