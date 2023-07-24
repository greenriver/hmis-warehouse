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

    def self.options_for_type(pick_list_type, user:, project_id: nil, client_id: nil, household_id: nil)
      result = static_options_for_type(pick_list_type)
      return result if result.present?

      project = Hmis::Hud::Project.viewable_by(user).find_by(id: project_id) if project_id.present?
      client = Hmis::Hud::Client.viewable_by(user).find_by(id: client_id) if client_id.present?

      case pick_list_type
      when 'COC'
        coc_picklist(project)
      when 'PROJECT'
        Hmis::Hud::Project.viewable_by(user).
          joins(:organization).
          preload(:organization).
          sort_by_option(:organization_and_name).
          map(&:to_pick_list_option)
      when 'ENROLLABLE_PROJECTS'
        Hmis::Hud::Project.viewable_by(user).with_access(user, :can_enroll_clients).
          joins(:organization).
          sort_by_option(:organization_and_name).
          preload(:organization).
          map(&:to_pick_list_option)
      when 'ORGANIZATION'
        Hmis::Hud::Organization.viewable_by(user).sort_by_option(:name).map(&:to_pick_list_option)
      when 'AVAILABLE_SERVICE_TYPES'
        available_service_types_picklist(project)
      when 'POSSIBLE_UNIT_TYPES_FOR_PROJECT'
        possible_unit_types_for_project(project)
      when 'AVAILABLE_UNIT_TYPES'
        available_unit_types_for_project(project)
      when 'AVAILABLE_UNITS_FOR_ENROLLMENT'
        available_units_for_enrollment(project, household_id: household_id)
      when 'OPEN_HOH_ENROLLMENTS_FOR_PROJECT'
        open_hoh_enrollments_for_project(project)
      when 'ENROLLMENTS_FOR_CLIENT'
        enrollments_for_client(client)
      end
    end

    # "Static" pick list options that do not depend on any other data
    def self.static_options_for_type(pick_list_type)
      case pick_list_type
      when 'STATE'
        state_picklist
      when 'GEOCODE'
        geocodes_picklist
      when 'VAMC_STATION'
        vamc_station_picklist
      when 'PRIOR_LIVING_SITUATION'
        living_situation_picklist(as: :prior)
      when 'ALL_SERVICE_TYPES'
        service_types_picklist
      when 'ALL_SERVICE_CATEGORIES'
        service_categories_picklist
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
      when 'AVAILABLE_FILE_TYPES'
        file_tag_picklist
      when 'ALL_UNIT_TYPES'
        # used for referrals between projects
        Hmis::UnitType.order(:description, :id).map(&:to_pick_list_option)
      end
    end

    def self.available_unit_types_for_project(project)
      return [] unless project.present?

      units = project.units.unoccupied_on

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

    # UNIT_TYPES pick list should only return types that are "mapped" for this project. If there are
    # no mappings it should return all unit types, which is the default behavior.
    def self.possible_unit_types_for_project(project)
      return [] unless project.present?

      unit_type_scope = Hmis::UnitType.all
      unit_type_ids = project.unit_type_mappings.active.pluck(:unit_type_id)
      if unit_type_ids.any?
        unit_type_ids += project.units.distinct.pluck(:unit_type_id) # include unit types for existing units
        unit_type_scope = unit_type_scope.where(id: unit_type_ids)
      end

      unit_type_scope
        .order(:description, :id)
        .map(&:to_pick_list_option)
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

    def self.vamc_station_picklist
      Rails.cache.fetch('VAMC_STATION_OPTION_LIST', expires_in: 1.days) do
        JSON.parse(File.read('drivers/hmis/lib/pick_list_data/vamc_stations.json'))
      end.map do |obj|
        {
          code: obj['value'],
          label: obj['text'],
        }
      end
    end

    def self.service_types_picklist
      options = Hmis::Hud::CustomServiceType.
        preload(:custom_service_category).to_a.
        map(&:to_pick_list_option).
        sort_by { |obj| obj[:group_label] + obj[:label] }

      options[0][:initial_selected] = true if options.size == 1

      options
    end

    def self.service_categories_picklist
      options = Hmis::Hud::CustomServiceCategory.all.
        to_a.
        map(&:to_pick_list_option).
        sort_by { |obj| obj[:label] }

      options[0][:initial_selected] = true if options.size == 1

      options
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
      tag_to_option = lambda do |tag|
        {
          code: tag.id,
          label: tag.name,
          group_code: tag.group,
          group_label: tag.group,
        }
      end

      other, file_tags = Hmis::File.all_available_tags.partition { |tag| tag.name == 'Other' }
      picklist = file_tags.
        map { |tag| tag_to_option.call(tag) }.
        compact.
        sort_by { |obj| [obj[:group_label] + obj[:label]].join(' ') }

      # Put 'Other' at the end
      picklist << tag_to_option.call(other.first) if other.any?
      picklist.compact
    end

    def self.open_hoh_enrollments_for_project(project)
      raise 'Project required' unless project.present?

      # No need for viewable_by here because we know the project is already veiwable by the user
      enrollments = project.enrollments.open_on_date
        .heads_of_households
        .preload(:client)
        .preload(household: :enrollments)

      enrollments.sort_by_option(:most_recent).map do |en|
        client = en.client
        household_size = en.household&.enrollments&.size || 0
        other_size = household_size - 1 # more than hoh
        desc = other_size.positive? ? "and #{other_size} #{'other'.pluralize(other_size)}" : ''
        {
          code: en.id,
          label: "#{client.brief_name} #{desc} (Entered #{en.entry_date.strftime('%m/%d/%Y')})",
        }
      end
    end

    def self.enrollments_for_client(client)
      raise 'Client required' unless client.present?

      enrollments = client.enrollments.preload(:project, :exit)
      enrollments.sort_by_option(:most_recent).map do |en|
        {
          code: en.id,
          label: "#{en.project.project_name} (#{[en.entry_date.strftime('%m/%d/%Y'), en.exit_date&.strftime('%m/%d/%Y') || 'Active'].join(' - ')})",
        }
      end
    end

    def self.available_units_for_enrollment(project, household_id: nil)
      raise 'Project required' unless project.present?

      # Eligible units are unoccupied units, PLUS units occupied by household members
      unoccupied_units = project.units.unoccupied_on.pluck(:id)

      hh_units = if household_id.present?
        hh_en_ids = project.enrollments_including_wip.where(household_id: household_id).pluck(:id)
        Hmis::UnitOccupancy.active.joins(:enrollment).where(enrollment_id: hh_en_ids).pluck(:unit_id)
      else
        []
      end

      Hmis::Unit.where(id: unoccupied_units + hh_units).
        preload(:unit_type).
        order(:unit_type_id, :id).
        map do |unit|
          {
            **unit.to_pick_list_option,
            # If unit is already assigned to other members of this household, show that
            secondary_label: hh_units.include?(unit.id) ? 'Assigned to Household' : nil,
            # If household already has some units assigned, select one of them as default
            initial_selected: unit.id == hh_units.first,
          }
        end
    end
  end
end
