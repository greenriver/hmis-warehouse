###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Versioned form definition. Contains a structured list of questions, information about how to render them, and information about available options and initial values. Nested recursive structure similar to FHIR Questionnaire.
#
# The canonical definitions are in json files under drivers/hmis/lib/form_data. When the json definitions changes, run the following command to freshen these db records
#   rails driver:hmis:seed_definitions
class Hmis::Form::Definition < ::GrdaWarehouseBase
  self.table_name = :hmis_form_definitions
  include Hmis::Hud::Concerns::HasEnums

  # convenience attr for passing graphql args
  attr_accessor :filter_context

  has_many :instances, foreign_key: :definition_identifier, primary_key: :identifier
  has_many :form_processors
  has_many :custom_service_types, through: :instances, foreign_key: :identifier, primary_key: :form_definition_identifier

  # Forms that are assessments
  HUD_ASSESSMENT_FORM_ROLES = [:INTAKE, :UPDATE, :ANNUAL, :EXIT, :CE, :POST_EXIT, :CUSTOM_ASSESSMENT].freeze

  # System forms (required for basic HMIS functionality)
  SYSTEM_FORM_ROLES = [
    :PROJECT,
    :ORGANIZATION,
    :PROJECT_COC,
    :FUNDER,
    :INVENTORY,
    :CLIENT,
    :NEW_CLIENT_ENROLLMENT,
    :ENROLLMENT,
  ].freeze

  # Forms used for data collection on Enrollments (features that can be "toggled" on and off by specifying Instances)
  DATA_COLLECTION_FEATURE_ROLES = [
    :CURRENT_LIVING_SITUATION,
    :SERVICE,
    :CE_EVENT,
    :CE_ASSESSMENT,
    :CASE_NOTE,
    # Would be nice if we could use instances to enable/disable the referral feature (instead of using permissions for it).
    # That would mean creating an Instance for this form for each non-Direct Entry program.
    # Maybe less cumbersome than dealing with data access groups, but we'd need that anyway to handle Direct Enrollment permission?
    :REFERRAL_REQUEST,
  ].freeze

  FORM_ROLES = [
    *HUD_ASSESSMENT_FORM_ROLES,
    *SYSTEM_FORM_ROLES,
    *DATA_COLLECTION_FEATURE_ROLES,
    :OCCURRENCE_POINT,
    # Other/misc forms
    :FILE, # should maybe be considered a data collection feature, but different becase its at Client-level (not Project)
  ].freeze

  validates :role, inclusion: { in: FORM_ROLES.map(&:to_s) }

  ENROLLMENT_CONFIG = {
    class_name: Hmis::Hud::Enrollment,
    permission: :can_edit_enrollments,
    resolve_as: 'Types::HmisSchema::Enrollment',
  }.freeze

  FORM_ROLE_CONFIG = {
    SERVICE: {
      class_name: Hmis::Hud::HmisService,
      permission: :can_edit_enrollments,
      resolve_as: 'Types::HmisSchema::Service',
    },
    PROJECT: {
      class_name: Hmis::Hud::Project,
      permission: :can_edit_project_details,
      resolve_as: 'Types::HmisSchema::Project',
    },
    ORGANIZATION: {
      class_name: Hmis::Hud::Organization,
      permission: :can_edit_organization,
      resolve_as: 'Types::HmisSchema::Organization',
    },
    CLIENT: {
      class_name: Hmis::Hud::Client,
      permission: :can_edit_clients,
      resolve_as: 'Types::HmisSchema::Client',
    },
    FUNDER: {
      class_name: Hmis::Hud::Funder,
      permission: :can_edit_project_details,
      resolve_as: 'Types::HmisSchema::Funder',
    },
    INVENTORY: {
      class_name: Hmis::Hud::Inventory,
      permission: :can_edit_project_details,
      resolve_as: 'Types::HmisSchema::Inventory',
    },
    PROJECT_COC: {
      class_name: Hmis::Hud::ProjectCoc,
      permission: :can_edit_project_details,
      resolve_as: 'Types::HmisSchema::ProjectCoc',
    },
    CE_ASSESSMENT: {
      class_name: Hmis::Hud::Assessment,
      permission: :can_edit_enrollments,
      resolve_as: 'Types::HmisSchema::CeAssessment',
    },
    CE_EVENT: {
      class_name: Hmis::Hud::Event,
      permission: :can_edit_enrollments,
      resolve_as: 'Types::HmisSchema::Event',
    },
    CASE_NOTE: {
      class_name: Hmis::Hud::CustomCaseNote,
      permission: :can_edit_enrollments,
      resolve_as: 'Types::HmisSchema::CustomCaseNote',
    },
    FILE: {
      class_name: 'Hmis::File',
      permission: [:can_manage_any_client_files, :can_manage_own_client_files],
      authorize: Hmis::File.authorize_proc,
      resolve_as: 'Types::HmisSchema::File',
    },
    REFERRAL_REQUEST: {
      class_name: 'HmisExternalApis::AcHmis::ReferralRequest',
      permission: :can_manage_incoming_referrals,
      resolve_as: 'Types::HmisSchema::ReferralRequest',
    },
    CURRENT_LIVING_SITUATION: {
      class_name: Hmis::Hud::CurrentLivingSituation,
      permission: :can_edit_enrollments,
      resolve_as: 'Types::HmisSchema::CurrentLivingSituation',
    },
    OCCURRENCE_POINT: ENROLLMENT_CONFIG,
    ENROLLMENT: ENROLLMENT_CONFIG,
    # This form creates an enrollment, but it ALSO creates a client, so it requires an additional permission
    NEW_CLIENT_ENROLLMENT: {
      **ENROLLMENT_CONFIG,
      permission: [:can_edit_clients, :can_edit_enrollments],
    },
  }.freeze

  FORM_DATA_COLLECTION_STAGES = {
    INTAKE: 1,
    UPDATE: 2,
    ANNUAL: 5,
    EXIT: 3,
    POST_EXIT: 6,
  }.freeze

  use_enum_with_same_key :form_role_enum_map, FORM_ROLES
  use_enum_with_same_key :assessment_type_enum_map, HUD_ASSESSMENT_FORM_ROLES
  use_enum_with_same_key :data_collection_feature_role_enum_map, DATA_COLLECTION_FEATURE_ROLES

  scope :with_role, ->(role) { where(role: role) }

  scope :for_project, ->(project:, role:, service_type: nil) do
    # Consider all instances for this role (and service type, if applicable)
    definition_scope = Hmis::Form::Definition.with_role(role)
    definition_scope = definition_scope.for_service_type(service_type) if service_type.present?
    base_scope = Hmis::Form::Instance.joins(:definition).merge(definition_scope)

    # Choose the first scope that has any records. Prefer more specific instances.
    instance_scope = Hmis::Form::Instance.detect_best_instance_scope_for_project(base_scope, project: project)
    return none unless instance_scope.present?

    where(identifier: instance_scope.pluck(:definition_identifier))
  end

  scope :for_service_type, ->(service_type) do
    base_scope = Hmis::Form::Instance.joins(:definition)

    instance_scope = [
      base_scope.for_service_type(service_type.id),
      base_scope.for_service_category(service_type.custom_service_category_id),
    ].detect(&:exists?)
    return none unless instance_scope.present?

    where(identifier: instance_scope.pluck(:definition_identifier))
  end

  def self.find_definition_for_role(role, project: nil, version: nil)
    if project.present?
      scope = Hmis::Form::Definition.for_project(project: project, role: role)
    else
      scope = Hmis::Form::Definition.with_role(role)
    end

    scope = scope.where(version: version) if version.present?
    scope.order(version: :desc).first
  end

  def self.find_definition_for_service_type(service_type, project:)
    Hmis::Form::Definition.
      for_project(project: project, role: :SERVICE, service_type: service_type).
      order(version: :desc).first
  end

  # Validate JSON definition when loading, to ensure no duplicate link IDs
  def self.validate_json(json, valid_pick_lists: [])
    seen_link_ids = Set.new

    recur_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']
        raise "Missing link ID: #{child_item}" unless link_id.present?
        raise "Duplicate link ID: #{link_id}" if seen_link_ids.include?(link_id)

        seen_link_ids.add(link_id)

        # Ensure pick list reference is valid
        raise "Invalid pick list for Link ID #{link_id}: #{child_item['pick_list_reference']}" if child_item['pick_list_reference'] && valid_pick_lists.exclude?(child_item['pick_list_reference'])

        recur_check.call(child_item)
      end
    end

    recur_check.call(json)
  end

  def self.validate_schema(json)
    schema_path = Rails.root.
      join('drivers/hmis_external_apis/public/schemas/form_definition.json')
    HmisExternalApis::JsonValidator.perform(json, schema_path)
  end

  def hud_assessment?
    HUD_ASSESSMENT_FORM_ROLES.include?(role.to_sym)
  end

  def intake?
    role.to_sym == :INTAKE
  end

  def exit?
    role.to_sym == :EXIT
  end

  def record_class_name
    return unless FORM_ROLE_CONFIG[role.to_sym].present?

    FORM_ROLE_CONFIG[role.to_sym][:class_name]
  end

  def record_editing_permissions
    return [] unless FORM_ROLE_CONFIG[role.to_sym].present?

    Array.wrap(FORM_ROLE_CONFIG[role.to_sym][:permission])
  end

  def allowed_proc
    return unless FORM_ROLE_CONFIG[role.to_sym].present?

    FORM_ROLE_CONFIG[role.to_sym][:authorize]
  end

  def assessment_date_item
    @assessment_date_item ||= link_id_item_hash.values.find(&:assessment_date)
  end

  def validate_form_values(form_values)
    errors = HmisErrors::Errors.new

    # Iterate over item hash so that errors are sorted according to the definition
    link_id_item_hash.each do |link_id, item|
      # Skip assessment date, it is validated separately
      next if item.assessment_date
      # Skip if not present in value hash
      next unless form_values.key?(link_id)

      value = form_values[link_id]

      error_context = {
        readable_attribute: item.brief_text || item.text,
        link_id: item.link_id,
        section: link_id_section_hash[item.link_id],
      }

      is_missing = value.nil? || (value.respond_to?(:empty?) && value.empty?)
      is_data_not_collected = value == 'DATA_NOT_COLLECTED'
      field_name = item.mapping&.field_name
      # Validate required status
      if item.required && is_missing
        errors.add field_name || :base, :required, **error_context
      elsif item.warn_if_empty && (is_missing || is_data_not_collected)
        errors.add field_name || :base, :data_not_collected, severity: :warning, **error_context
      end

      # Additional validations for currency
      errors.add field_name, :out_of_range, **error_context, message: 'must be positive' if item.type == 'CURRENCY' && value&.negative?

      # TODO(##184404620): Validate ValueBounds (How to handle bounds that rely on local values like projectStartDate and entryDate?)
      # TODO(##184402463): Add support for RequiredWhen
    end

    # Ensure all link IDs are in the FormDefinition
    form_values.each do |link_id, _|
      raise "Unrecognized link ID: #{link_id} for definition #{identifier}" unless link_id_item_hash.key?(link_id)
    end

    errors.errors
  end

  private def definition_struct
    @definition_struct ||= Oj.load(definition.to_json, mode: :compat, object_class: OpenStruct)
  end

  # Hash { link_id => FormItem }
  def link_id_item_hash
    @link_id_item_hash ||= begin
      item_map = {}
      recur_fill = lambda do |items|
        items.each do |item|
          recur_fill.call(item.item) if item.item
          item_map[item.link_id] = item unless item.type == 'GROUP'
        end
      end

      recur_fill.call(definition_struct.item)
      item_map
    end
  end

  # Hash { link_id => section label ("Income and Sources") }
  def link_id_section_hash
    @link_id_section_hash ||= begin
      item_map = {}
      recur_fill = lambda do |items, level, label|
        items.each do |item|
          label = item.brief_text || item.text if level.zero?
          recur_fill.call(item.item, level + 1, label) if item.item
          item_map[item.link_id] = label
        end
      end

      recur_fill.call(definition_struct.item, 0, nil)
      item_map
    end
  end

  # Unused
  def apply_conditionals(enrollment)
    parsed = JSON.parse(definition)
    client = enrollment.client
    parsed['item'].delete_if { |item| irrelevant_item?(item, enrollment, client) }
    self.definition = parsed.to_json
  end

  # Unused
  private def irrelevant_item?(item, enrollment, client)
    condition = item['data_collected_about']
    return !matches_condition(condition, enrollment, client) if condition.present?

    item['item'].delete_if { |child| irrelevant_item?(child, enrollment, client) } if item['item'].present?
    false
  end

  # Unused
  private def matches_condition(condition, enrollment, client)
    case condition
    when 'ALL_CLIENTS'
      true
    when 'HOH'
      enrollment.RelationshipToHoH == 1
    when 'HOH_AND_ADULTS'
      enrollment.RelationshipToHoH == 1 || client.age >= 18
    else
      raise NotImplementedError
    end
  end
end
