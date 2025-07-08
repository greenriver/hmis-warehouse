###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      return result unless result.nil? # check nil so we return an empty array if it was static but there were no options

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
      when 'OPEN_PROJECTS'
        Hmis::Hud::Project.viewable_by(user).open_on_date(Date.current).
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
      when 'ADMIN_AVAILABLE_UNITS_FOR_ENROLLMENT'
        admin_available_units_for_enrollment(project, household_id: household_id)
      when 'OPEN_HOH_ENROLLMENTS_FOR_PROJECT'
        open_hoh_enrollments_for_project(project, user: user)
      when 'ENROLLMENTS_FOR_CLIENT'
        enrollments_for_client(client, user: user)
      when 'EXTERNAL_FORM_TYPES_FOR_PROJECT'
        external_form_types_for_project(project)
      when 'ASSESSMENT_NAMES'
        assessment_names_for_project(project)
      when 'STAFF_ASSIGNMENT_RELATIONSHIPS'
        staff_assignment_relationships(project)
      when 'ELIGIBLE_STAFF_ASSIGNMENT_USERS'
        eligible_staff_assignment_user_picklist(project)
      when 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS'
        eligible_referral_step_assignment_user_picklist(project)
      when 'CE_REFERRAL_STATUSES'
        Hmis::Ce::CustomReferralStatus.viewable_by(user)
      else
        raise "Unknown pick list type: #{pick_list_type}"
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
      when 'CUSTOM_SERVICE_CATEGORIES'
        service_categories_picklist(custom_only: true)
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
      when 'USERS', 'AUDITABLE_USERS'
        user_picklist(user)
      when 'ENROLLMENT_AUDIT_EVENT_RECORD_TYPES'
        enrollment_audit_event_record_type_picklist
      when 'CLIENT_AUDIT_EVENT_RECORD_TYPES'
        client_audit_event_record_type_picklist
      when 'PROJECTS_RECEIVING_REFERRALS'
        projects_receiving_referrals(user.hmis_data_source_id)
      when 'FORM_TYPES'
        # Used in the dropdown of form roles when creating/editing a form. We need a permission check here because
        # not all users can access all form types:
        form_types = if user.can_administrate_config?
          # Super-admins should be able to select any form type when creating a form
          Hmis::Form::Definition.form_role_enum_map.members
        else
          # Other users should only see the limited list roles that we have designated for general editing, like service and custom assessment
          Hmis::Form::Definition.non_admin_form_role_enum_map.members
        end

        form_types.map { |ft| { code: ft[:value], label: ft[:desc] } }
      when 'CONTINUUM_PROJECTS'
        Hmis::Hud::Project.
          where(data_source_id: user.hmis_data_source_id, continuum_project: true).
          preload(:organization).
          sort_by_option(:organization_and_name).
          map(&:to_pick_list_option)
      when 'OTHER_FUNDERS'
        Hmis::Hud::Funder.where(data_source_id: user.hmis_data_source_id).
          where(Funder: HudUtility2024.local_or_other_funding_source).where.not(OtherFunder: nil).
          pluck(:OtherFunder).uniq.sort.map do |other_funder|
            { code: other_funder, label: other_funder }
          end
      when 'CE_WORKFLOW_TEMPLATE_IDENTIFIERS'
        # Unique ce workflow template identifiers that are currently published.
        # Used for configuring which template to use for a resource group
        return [] unless Hmis::Ce.configuration.enabled?

        Hmis::WorkflowDefinition::Template.published.ce.viewable_by(user).
          map do |template|
            { code: template.identifier, label: template.name }
          end
      when 'CE_WORKFLOW_TEMPLATE_IDENTIFIERS_INCLUDING_RETIRED'
        # Unique CE workflow template identifiers, including retired workflows with no currently published version.
        # Used for filtering on existing/historical referrals.
        return [] unless Hmis::Ce.configuration.enabled?

        base_scope = Hmis::WorkflowDefinition::Template.ce.viewable_by(user)
        base_scope.published.or(base_scope.retired).group_by(&:identifier).map do |identifier, templates|
          description = templates.find { |t| t.status.to_sym == :published }&.name || templates.max_by(&:version).name
          { code: identifier, label: description }
        end
      when 'PROJECT_CONFIG_TYPES'
        # Project config types for selection on the Admin Project Config page.
        # Hide Coordinated Entry option if CE is not enabled in the installation.
        Types::HmisSchema::Enums::ProjectConfigType.values.map do |key, enum|
          next if key == 'COORDINATED_ENTRY' && !Hmis::Ce.configuration.enabled?

          {
            code: key,
            label: enum.description,
          }
        end.compact
      end
    end

    def self.eligible_staff_assignment_user_picklist(project)
      return [] unless project&.staff_assignments_enabled?

      Hmis::User.can_edit_enrollments_for(project).
        order(:last_name, :first_name, :id).
        map(&:to_pick_list_option)
    end

    def self.eligible_referral_step_assignment_user_picklist(project)
      return [] unless Hmis::Ce.configuration.enabled?
      return [] unless project.present? # TODO(#7409) - when project-level CE configuration exists, check it here

      user_scope = Hmis::User.active

      user_scope.can_perform_any_referral_tasks_for(project).
        or(user_scope.can_perform_own_referral_tasks_for(project)).
        order(:last_name, :first_name, :id).
        map(&:to_pick_list_option).uniq
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
        ::HudUtility2024.cocs_in_state(GrdaWarehouse::Config.relevant_state_codes)
      end

      available_codes.sort.map do |code, name|
        { code: code, label: "#{code} - #{name}", initial_selected: available_codes.length == 1 }
      end
    end

    def self.geocodes_picklist
      GrdaWarehouse::Config.relevant_state_codes.flat_map do |state|
        Rails.cache.fetch(['GEOCODES', state], expires_in: 1.days) do
          JSON.parse(File.read("drivers/hmis/lib/pick_list_data/geocodes/geocodes-#{state}.json"))
        end.map do |obj|
          {
            code: obj['geocode'],
            label: "#{obj['geocode']} - #{obj['name']}",
            group_label: state,
          }
        end
      end
    end

    def self.state_picklist
      relevant_states = GrdaWarehouse::Config.relevant_state_codes

      Rails.cache.fetch('STATE_OPTION_LIST', expires_in: 1.days) do
        JSON.parse(File.read('drivers/hmis/lib/pick_list_data/states.json'))
      end.map do |obj|
        {
          code: obj['abbreviation'],
          # label: "#{obj['abbreviation']} - #{obj['name']}",
          initial_selected: relevant_states&.size == 1 && obj['abbreviation'] == relevant_states.first,
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

    def self.service_categories_picklist(custom_only: false)
      scope = custom_only ? Hmis::Hud::CustomServiceCategory.non_hud : Hmis::Hud::CustomServiceCategory.all

      options = scope.to_a.
        map(&:to_pick_list_option).
        sort_by { |obj| obj[:label] }

      options[0][:initial_selected] = true if options.size == 1

      options
    end

    def self.available_service_types_picklist(project, bulk_only: false)
      return [] unless project.present?

      service_types = project.available_service_types
      service_types = service_types.where(supports_bulk_assignment: true) if bulk_only

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

    # This is used for selecting a household for an "outgoing referral"
    def self.open_hoh_enrollments_for_project(project, user:)
      return [] unless project

      enrollments = project.enrollments.viewable_by(user).
        open_excluding_wip.
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

    def self.external_form_types_for_project(project)
      return [] unless project

      # External forms can only be enabled by Project-level instances
      Hmis::Form::Instance.for_project(project).active.published.
        with_role(:EXTERNAL_FORM).
        preload(:definition).
        order(:id).
        map(&:to_pick_list_option).uniq
    end

    def self.enrollments_for_client(client, user:)
      return [] unless client

      enrollments = client.enrollments.viewable_by(user).preload(:project, :exit)
      enrollments.sort_by_option(:most_recent).map do |en|
        {
          code: en.id,
          label: "#{en.project.project_name} (#{[en.entry_date.strftime('%m/%d/%Y'), en.exit_date&.strftime('%m/%d/%Y') || 'Active'].join(' - ')})",
        }
      end
    end

    def self.admin_available_units_for_enrollment(project, household_id: nil)
      return [] unless project

      # Eligible units are unoccupied units, PLUS units occupied by household members
      unoccupied_units = project.units.unoccupied_on.pluck(:id)
      # IDs of units that are currently assigned to members of this household
      hh_units = if household_id.present?
        hh_en_ids = project.enrollments.where(household_id: household_id).pluck(:id)
        Hmis::UnitOccupancy.active.joins(:enrollment).where(enrollment_id: hh_en_ids).pluck(:unit_id)
      else
        []
      end

      eligible_units = Hmis::Unit.where(id: unoccupied_units + hh_units)

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

    def self.available_units_for_enrollment(project, household_id: nil)
      return [] unless project

      # use picklist that includes all available units including units of other types
      picklist = admin_available_units_for_enrollment(project, household_id: household_id)
      return picklist unless household_id # no household, so no need to filter unit types

      # drop units that have different types
      hh_unit_type_ids = project.enrollments.where(household_id: household_id).map(&:current_unit_type).compact.map(&:id).uniq
      return picklist if hh_unit_type_ids.empty? # household doesn't have a unit type, so no need for further filtering

      # if the household has a unit type, exclude units that don't match
      allowed_unit_type_unit_ids = project.units.where(unit_type_id: hh_unit_type_ids).pluck(:id).to_set
      picklist.filter do |option|
        option[:code].in?(allowed_unit_type_unit_ids)
      end
    end

    def self.assessment_names_for_project(project)
      # It's a little odd to combine the "roles" (eg INTAKE) with the identifiers (eg housing_needs_assessment), but
      # we need to do that in order to get the desired behavior. The "Intake" option should show all Intakes,
      # regardless of what form they used.

      # get all form rules for custom assessments (active and inactive)
      scope = Hmis::Form::Instance.with_role(:CUSTOM_ASSESSMENT)
      # filter down to rules that match this project, if project is specified
      scope = scope.filter { |fi| fi.project_match(project) } if project
      # { code: definition.identifier, label: definition.title }
      custom_options = scope.map(&:to_pick_list_option).uniq.sort_by { |opt| opt[:label] }
      hud_options = Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES.excluding(:CUSTOM_ASSESSMENT).keys.
        map { |k| { code: k.to_s, label: k.to_s.humanize } }

      hud_options + custom_options
    end

    def self.staff_assignment_relationships(project)
      return [] unless project&.staff_assignments_enabled?

      Hmis::StaffAssignmentRelationship.all.map(&:to_pick_list_option)
    end

    def self.projects_receiving_referrals(data_source_id)
      Hmis::Hud::Project.where(data_source_id: data_source_id).
        receiving_referrals.
        joins(:organization).preload(:organization).
        sort_by_option(:organization_and_name).
        map(&:to_pick_list_option)
    end
  end
end
