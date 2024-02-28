###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::PickListOption < Types::BaseObject
    skip_activity_log
    include Hmis::Concerns::HmisArelHelper

    field :code, String, 'Code for the option', null: false
    field :label, String, 'Label for the option', null: true
    field :secondary_label, String, 'Secondary label, such as project type or CoC code', null: true
    field :group_code, String, 'Code for group that option belongs to, if grouped', null: true
    field :group_label, String, 'Label for group that option belongs to, if grouped', null: true
    field :initial_selected, Boolean, 'Whether option is selected by default', null: true
    field :numeric_value, Integer, 'Numeric value, such as a score', null: true
    field :helper_text, String, 'Helper text/html', null: true

    CODE_PATTERN = /^\(([0-9]*)\) /

    def self.options_for_type(pick_list_type, user:, project_id: nil, client_id: nil, household_id: nil)
      result = static_options_for_type(pick_list_type, user: user)
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
      when 'RESIDENTIAL_PROJECTS'
        Hmis::Hud::Project.viewable_by(user).
          # TODO: replace with call to HudUtility once project type groupings are moved there.
          # FIXME: internally our definition of "residential" includes 4 (SO) and 9 (OPH) which
          # are not valid for Residential project affiliations.
          where(project_type: HudUtility2024.residential_project_type_ids).
          preload(:organization).
          sort_by_option(:organization_and_name).
          map(&:to_pick_list_option)
      when 'ORGANIZATION'
        Hmis::Hud::Organization.viewable_by(user).sort_by_option(:name).map(&:to_pick_list_option)
      when 'AVAILABLE_SERVICE_TYPES'
        available_service_types_picklist(project)
      when 'AVAILABLE_BULK_SERVICE_TYPES'
        available_service_types_picklist(project, bulk_only: true)
      when 'POSSIBLE_UNIT_TYPES_FOR_PROJECT'
        possible_unit_types_for_project(project)
      when 'AVAILABLE_UNIT_TYPES'
        available_unit_types_for_project(project)
      when 'AVAILABLE_UNITS_FOR_ENROLLMENT'
        available_units_for_enrollment(project, household_id: household_id)
      when 'OPEN_HOH_ENROLLMENTS_FOR_PROJECT'
        open_hoh_enrollments_for_project(project)
      when 'ENROLLMENTS_FOR_CLIENT'
        enrollments_for_client(client, user: user)
      end
    end

    # "Static" pick list options that do not depend on any other data
    def self.static_options_for_type(pick_list_type, user:)
      case pick_list_type
      when 'STATE'
        state_picklist
      when 'GEOCODE'
        geocodes_picklist
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
      when 'CE_EVENTS'
        # group CE event types as specified in HUD Data Dictionary
        Types::HmisSchema::Enums::Hud::EventType.values.excluding('INVALID').
          partition { |_k, v| [1, 2, 3, 4].include?(v.value) }.
          map.with_index do |l, idx|
            group = idx.zero? ? 'Access Events' : 'Referral Events'
            l.map do |k, v|
              { code: k, label: v.description.gsub(CODE_PATTERN, ''), group_label: group }
            end
          end.flatten
      when 'USERS'
        user_picklist(user)
      when 'ENROLLMENT_AUDIT_EVENT_RECORD_TYPES'
        enrollment_audit_event_record_type_picklist
      when 'CLIENT_AUDIT_EVENT_RECORD_TYPES'
        client_audit_event_record_type_picklist
      end
    end

    def self.user_picklist(current_user)
      return [] unless current_user
      # currently picklist is only needed when filtering audit events, and when filtering client merge history
      return [] unless current_user.can_audit_enrollments? || current_user.can_audit_clients? || current_user.can_merge_clients?

      Hmis::User.with_deleted.map do |user|
        {
          code: user.id.to_s,
          label: user.full_name,
          group_code: user.pick_list_group_label, # Group by status (Active/Inactive/Deleted)
          group_label: user.pick_list_group_label,
        }
      end.sort_by { |obj| [obj[:group_label], obj[:label], obj[:code]].join(' ') }
    end

    def self.enrollment_audit_event_record_type_picklist
      [
        [Hmis::Hud::Enrollment],
        [Hmis::Hud::CustomAssessment],
        [Hmis::Hud::CurrentLivingSituation],
        [Hmis::Hud::Service],
        [Hmis::Hud::IncomeBenefit],
        [Hmis::Hud::HealthAndDv],
        [Hmis::Hud::EmploymentEducation],
        [Hmis::Hud::YouthEducationStatus],
        [Hmis::Hud::Disability],
        [Hmis::Hud::Exit],
        [Hmis::Hud::Event, 'CE Event'],
        [Hmis::Hud::Assessment, 'CE Assessment'],
        [Hmis::Hud::CustomDataElement, 'Custom Field'],
        [Hmis::Hud::CustomCaseNote],
      ].map do |model, name|
        model_picklist_item(model: model, name: name)
      end.sort_by { |h| h[:label] }
    end

    def self.client_audit_event_record_type_picklist
      client_audited_models = [
        [Hmis::Hud::Client],
        [Hmis::Hud::CustomClientAddress],
        [Hmis::Hud::CustomClientContactPoint, 'Contact Information'],
      ]
      # If installation has any custom client fields, include a general filter option for them
      has_client_cdes = Hmis::Hud::CustomDataElementDefinition.for_type(Hmis::Hud::Client.sti_name).exists?
      client_audited_models << [Hmis::Hud::CustomDataElement, 'Custom Field'] if has_client_cdes
      client_audited_models.map do |model, name|
        model_picklist_item(model: model, name: name)
      end.sort_by { |h| h[:label] }
    end

    def self.model_picklist_item(model:, name:)
      { code: model.sti_name, label: name || model.name.demodulize.gsub(/^Custom(Client)?/, '').titleize }
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

      unit_type_scope.
        order(:description, :id).
        map(&:to_pick_list_option)
    end

    def self.coc_picklist(selected_project)
      available_codes = if selected_project.present?
        selected_project.project_cocs.pluck(:CoCCode).uniq.map { |code| [code, ::HudUtility2024.cocs[code] || code] }
      else
        ::HudUtility2024.cocs_in_state(ENV['RELEVANT_COC_STATE'])
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

    def self.available_service_types_picklist(project, bulk_only: false)
      return [] unless project.present?

      service_types = project.available_service_types
      service_types = service_types.where(bulk: true) if bulk_only

      options = service_types.preload(:custom_service_category).to_a.
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
      enum_value_definitions = case as
      when :prior
        Types::HmisSchema::Enums::Hud::PriorLivingSituation.all_enum_value_definitions
      when :current
        Types::HmisSchema::Enums::Hud::CurrentLivingSituation.all_enum_value_definitions
      when :destination
        Types::HmisSchema::Enums::Hud::Destination.all_enum_value_definitions
      end

      [
        [HudUtility2024::SITUATION_HOMELESS_RANGE, :HOMELESS, 'Homeless Situations'],
        [HudUtility2024::SITUATION_INSTITUTIONAL_RANGE, :INSTITUTIONAL, 'Institutional Situations'],
        [HudUtility2024::SITUATION_TEMPORARY_RANGE, :TEMPORARY, 'Temporary Housing Situations'],
        [HudUtility2024::SITUATION_PERMANENT_RANGE, :PERMANENT, 'Permanent Housing Situations'],
        [HudUtility2024::SITUATION_OTHER_RANGE, :OTHER, 'Other'],
      ].map do |range, group_code, group_label|
        enum_value_definitions.select { |e| range.include? e.value }.map do |enum|
          {
            code: enum.graphql_name,
            label: ::HudUtility2024.living_situation(enum.value),
            group_code: group_code,
            group_label: group_label,
          }
        end
      end.flatten
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
        sort_by { |obj| [obj[:group_label], obj[:label]].join(' ') }

      # Put 'Other' at the end
      picklist << tag_to_option.call(other.first) if other.any?
      picklist.compact
    end

    def self.open_hoh_enrollments_for_project(project)
      raise 'Project required' unless project.present?

      # No need for viewable_by here because we know the project is already veiwable by the user
      enrollments = project.enrollments.
        open_on_date(Date.current + 1.day). # exclude clients that exited today
        heads_of_households.
        preload(:client).
        preload(household: :enrollments)

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

    def self.enrollments_for_client(client, user:)
      raise 'Client required' unless client.present?

      enrollments = client.enrollments.viewable_by(user).preload(:project, :exit)
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
      # IDs of units that are currently assigned to members of this household
      hh_units = if household_id.present?
        hh_en_ids = project.enrollments_including_wip.where(household_id: household_id).pluck(:id)
        Hmis::UnitOccupancy.active.joins(:enrollment).where(enrollment_id: hh_en_ids).pluck(:unit_id)
      else
        []
      end

      unit_types_assigned_to_household = Hmis::Unit.where(id: hh_units).pluck(:unit_type_id).compact.uniq
      eligible_units = Hmis::Unit.where(id: unoccupied_units + hh_units)
      # If some household members are assigned to units with unit types, then list should be limited to units of the same type.
      eligible_units = eligible_units.where(unit_type_id: unit_types_assigned_to_household) if unit_types_assigned_to_household.any?
      eligible_units.preload(:unit_type).
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
