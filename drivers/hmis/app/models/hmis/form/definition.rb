###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Versioned form definition. Contains a structured list of questions, information about how to render them, and information about available options and initial values. Nested recursive structure similar to FHIR Questionnaire.
#
# The canonical definitions are in json files under drivers/hmis/lib/form_data. When the json definitions changes, run the following command to freshen these db records
#   rails driver:hmis:seed_definitions
#
# Table: hmis_form_definitions
#   identifier
#     stable identifier for this form across version. Is the foreign key for form instances (rules)
#   version
#     in combination with identifier, uniquely identify this form
#   role
#     the significance of this form within the system (INTAKE, EXIT, etc)
#   status
#     NOT IMPLEMENTED: aspirational support for draft status
#   definition
#     JSON field defines the inputs, labels, validation, and mapping to HMIS fields. A JSON-schema exists to validate
#     the format of the definition
#   title
#     User-facing title of the form definition
class Hmis::Form::Definition < ::GrdaWarehouseBase
  self.table_name = :hmis_form_definitions
  acts_as_paranoid
  include ::Hmis::Concerns::HmisArelHelper

  # There is no need to track the JSON blob, because form should be immutable once they are managed through the Form Editor config tool.
  # When changes are needed, they will be applied to a duplicated Hmis::Form::Definition with a bumped `version`.
  has_paper_trail(
    version: :paper_version, # dont conflict with `version` column. will this break something? https://github.com/paper-trail-gem/paper_trail#6-extensibility
    skip: [:definition], # skip controls whether paper_trail will save that field with the version record
  )

  include Hmis::Hud::Concerns::HasEnums

  # convenience attr for passing graphql args
  attr_accessor :filter_context

  # --- Relations by id ----
  has_many :form_processors, dependent: :restrict_with_exception
  has_many :external_form_submissions, class_name: 'HmisExternalApis::ExternalForms::FormSubmission', dependent: :restrict_with_exception
  has_many :external_form_publications, class_name: 'HmisExternalApis::ExternalForms::FormPublication', dependent: :destroy

  # --- Relations by identifier ----
  has_many :instances, foreign_key: 'definition_identifier', primary_key: 'identifier'
  has_many :custom_service_types, through: :instances, foreign_key: 'identifier', primary_key: 'form_definition_identifier'
  has_many :custom_data_element_definitions, class_name: 'Hmis::Hud::CustomDataElementDefinition', primary_key: 'identifier', foreign_key: 'form_definition_identifier'
  has_one :published_version, -> { order(version: :desc).published }, class_name: 'Hmis::Form::Definition', primary_key: 'identifier', foreign_key: 'identifier'
  has_one :draft_version, -> { order(version: :desc).draft }, class_name: 'Hmis::Form::Definition', primary_key: 'identifier', foreign_key: 'identifier'
  has_many :all_versions, class_name: 'Hmis::Form::Definition', primary_key: 'identifier', foreign_key: 'identifier'

  # Forms that are used for Assessments. These are submitted using SubmitAssessment mutation.
  ASSESSMENT_FORM_ROLES = [:INTAKE, :UPDATE, :ANNUAL, :EXIT, :POST_EXIT, :CUSTOM_ASSESSMENT].freeze

  # "System" Record-editing Forms
  # These are forms that are *required* for basic HMIS functionality, and are configurable.
  # These are submitted using SubmitForm mutation.
  SYSTEM_FORM_ROLES = [
    :PROJECT,
    :ORGANIZATION,
    :PROJECT_COC,
    :FUNDER,
    :INVENTORY,
    :CLIENT,
    :NEW_CLIENT_ENROLLMENT,
    :ENROLLMENT,
    :HMIS_PARTICIPATION,
    :CE_PARTICIPATION,
  ].freeze

  # "Data Collection Feature" Record-editing Forms
  # These are forms that are *optional* for HMIS functionality, and are configurable. They
  # are primarily for Enrollment-level data collection.
  #
  # Each one is considered a feature that can be "toggled on" for a given project by enabling
  # a Form Instance for it.
  # These are submitted using SubmitForm mutation.
  DATA_COLLECTION_FEATURE_ROLES = [
    :CURRENT_LIVING_SITUATION,
    :SERVICE,
    :CE_EVENT,
    :CE_ASSESSMENT,
    :CASE_NOTE,
    :REFERRAL,
    :REFERRAL_REQUEST,
    :EXTERNAL_FORM,
  ].freeze

  # Static Forms
  # Non-configurable forms. These are submitted using custom mutations.
  STATIC_FORM_ROLES = [
    :FORM_RULE,
    :AUTO_EXIT_CONFIG,
    :PROJECT_CONFIG,
    :CLIENT_ALERT,
    :FORM_DEFINITION,
    :EXTERNAL_FORM_SUBMISSION_REVIEW,
  ].freeze

  # All form roles
  FORM_ROLES = [
    *ASSESSMENT_FORM_ROLES,
    *SYSTEM_FORM_ROLES,
    *DATA_COLLECTION_FEATURE_ROLES,
    *STATIC_FORM_ROLES,
    :OCCURRENCE_POINT,
    :CLIENT_DETAIL,
    # Other/misc forms
    :FILE, # should maybe be considered a data collection feature, but different because its at Client-level (not Project)
  ].freeze

  validates :role, inclusion: { in: FORM_ROLES.map(&:to_s) }
  validates :identifier, uniqueness: { scope: :version }

  ENROLLMENT_CONFIG = {
    owner_class: 'Hmis::Hud::Enrollment',
    permission: :can_edit_enrollments,
  }.freeze

  # Configuration for SubmitForm
  FORM_ROLE_CONFIG = {
    SERVICE: {
      owner_class: 'Hmis::Hud::HmisService',
      permission: :can_edit_enrollments,
    },
    PROJECT: {
      owner_class: 'Hmis::Hud::Project',
      permission: :can_edit_project_details,
    },
    ORGANIZATION: {
      owner_class: 'Hmis::Hud::Organization',
      permission: :can_edit_organization,
    },
    CLIENT: {
      owner_class: 'Hmis::Hud::Client',
      permission: :can_edit_clients,
    },
    FUNDER: {
      owner_class: 'Hmis::Hud::Funder',
      permission: :can_edit_project_details,
    },
    INVENTORY: {
      owner_class: 'Hmis::Hud::Inventory',
      permission: :can_edit_project_details,
    },
    PROJECT_COC: {
      owner_class: 'Hmis::Hud::ProjectCoc',
      permission: :can_edit_project_details,
    },
    HMIS_PARTICIPATION: {
      owner_class: 'Hmis::Hud::HmisParticipation',
      permission: :can_edit_project_details,
    },
    CE_PARTICIPATION: {
      owner_class: 'Hmis::Hud::CeParticipation',
      permission: :can_edit_project_details,
    },
    CE_ASSESSMENT: {
      owner_class: 'Hmis::Hud::Assessment',
      permission: :can_edit_enrollments,
    },
    CE_EVENT: {
      owner_class: 'Hmis::Hud::Event',
      permission: :can_edit_enrollments,
    },
    CASE_NOTE: {
      owner_class: 'Hmis::Hud::CustomCaseNote',
      permission: :can_edit_enrollments,
    },
    FILE: {
      owner_class: 'Hmis::File',
      permission: [:can_manage_any_client_files, :can_manage_own_client_files],
      authorize: ->(entity_base, user) { Hmis::File.authorize_proc.call(entity_base, user) },
    },
    REFERRAL_REQUEST: {
      owner_class: 'HmisExternalApis::AcHmis::ReferralRequest',
      permission: :can_manage_incoming_referrals,
    },
    REFERRAL: {
      owner_class: 'HmisExternalApis::AcHmis::ReferralPosting',
      # Note: this permission should be checked against the project that is _sending_ the referral,
      # not the project that is receiving it.
      permission: :can_manage_outgoing_referrals,
    },
    CURRENT_LIVING_SITUATION: {
      owner_class: 'Hmis::Hud::CurrentLivingSituation',
      permission: :can_edit_enrollments,
    },
    OCCURRENCE_POINT: ENROLLMENT_CONFIG,
    ENROLLMENT: ENROLLMENT_CONFIG,
    # This form creates an enrollment, but it ALSO creates a client, so it requires an additional permission
    NEW_CLIENT_ENROLLMENT: {
      **ENROLLMENT_CONFIG,
      permission: [:can_edit_clients, :can_edit_enrollments],
    },
    CLIENT_DETAIL: {
      owner_class: 'Hmis::Hud::Client',
      permission: :can_edit_clients,
    },
    EXTERNAL_FORM: {
      owner_class: 'HmisExternalApis::ExternalForms::FormSubmission',
      permission: :can_manage_external_form_submissions,
    },
  }.freeze

  # HUD-defined numeric representation of Data Collection Stage for each HUD Assessment
  FORM_DATA_COLLECTION_STAGES = {
    INTAKE: 1,
    UPDATE: 2,
    ANNUAL: 5,
    EXIT: 3,
    POST_EXIT: 6,
    CUSTOM_ASSESSMENT: 99,
  }.freeze
  NON_QUESTION_ITEM_TYPES = ['DISPLAY', 'GROUP'].freeze

  # Forms that are editable by users with can_manage_forms permission, and viewable/configurable (e.g. form rules)
  # by users with can_configure_data_collection (without needing the 'super-admin' permission can_administrate_config)
  NON_ADMIN_FORM_ROLES = [
    'SERVICE',
    'CUSTOM_ASSESSMENT',
  ].freeze

  # All form roles
  use_enum_with_same_key :form_role_enum_map, FORM_ROLES.excluding(:CE)
  # Form roles that can be used with SubmitForm for editing records
  use_enum_with_same_key :record_form_role_enum_map, FORM_ROLES.excluding(*ASSESSMENT_FORM_ROLES, *STATIC_FORM_ROLES)
  # Form roles for Assessments
  use_enum_with_same_key :assessment_type_enum_map, ASSESSMENT_FORM_ROLES
  # Form roles that represent optional "features"
  use_enum_with_same_key :data_collection_feature_role_enum_map, DATA_COLLECTION_FEATURE_ROLES
  # Form roles that are static
  use_enum_with_same_key :static_form_role_enum_map, STATIC_FORM_ROLES
  # Form roles that are non-admin; see comment above on NON_ADMIN_FORM_ROLES
  use_enum_with_same_key :non_admin_form_role_enum_map, NON_ADMIN_FORM_ROLES

  scope :exclude_definition_from_select, -> {
    # Get all column names except 'definition'
    select(column_names - ['definition'])
  }

  scope :with_role, ->(role) { where(role: role) }

  before_destroy :can_be_destroyed, prepend: true
  private def can_be_destroyed
    return if draft?

    errors.add(:base, 'Non-draft form cannot be destroyed')
    throw :abort
  end

  # Finding the appropriate form definition for a project:
  #  * find the active published definitions for the required role (i.e. INTAKE)
  #  * choose the form instance with the most specific match that is also associated with any of those definitions
  #  * return the published version of the definition that is referenced by that instance
  def self.for_project(project:, role:, service_type: nil)
    # Consider all Active, Published Forms for this Role
    definition_scope = Hmis::Form::Definition.with_role(role).
      active. # Drop definitions that have no active rules
      published

    # Filter by Service Type if specified
    definition_scope = definition_scope.for_service_type(service_type) if service_type.present?

    # Scope of active Instances (Rules) that are are associated with the eligible definitions
    instance_scope = Hmis::Form::Instance.joins(:definition).merge(definition_scope).active
    # Choose the Instance that is the "best match" for this Project (e.g. prefer project-specific rule, then org-specific, default rule, etc.)
    selected_instance = instance_scope.detect_best_instance_for_project(project: project)
    return unless selected_instance # No match found. This is OK for non-system roles, like CurrentLivingSituation.

    # Safe to use `find_by` because definition_scope is already restricted to published versions,
    # and there can be at most 1 published FormDefinition per identifier.
    definition_scope.find_by(identifier: selected_instance.definition_identifier)
  end

  # Helper scope to drop forms that are not valid, because their role is outside of FORM_ROLES.
  # This is just to help with local development when switching between branches that support different roles.
  scope :valid, -> { where(role: FORM_ROLES) }

  scope :non_static, -> { where.not(role: STATIC_FORM_ROLES) }

  scope :active, -> do
    where(identifier: Hmis::Form::Instance.active.select(:definition_identifier))
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

  scope :latest_versions, -> do
    # Returns the latest version per identifier
    one_for_column([:version], source_arel_table: Hmis::Form::Definition.arel_table, group_on: :identifier)
  end

  RETIRED = 'retired'.freeze
  PUBLISHED = 'published'.freeze
  DRAFT = 'draft'.freeze
  STATUSES = [RETIRED, PUBLISHED, DRAFT].freeze
  validates :status, inclusion: {
    in: STATUSES,
    message: '%{value} is not a valid status',
  }

  scope :retired, -> do
    where(status: RETIRED)
  end

  scope :draft, -> do
    where(status: DRAFT)
  end

  scope :published, -> do
    where(status: PUBLISHED)
  end

  def self.apply_filters(input)
    Hmis::Filter::FormDefinitionFilter.new(input).filter_scope(self)
  end

  def self.find_definition_for_role(role, project: nil)
    selected_definition = if project.present?
      # Chooses the published FormDefinition that is "most relevant" for the Project (via an active FormInstance)
      Hmis::Form::Definition.for_project(project: project, role: role)
    else
      # Project was not specified, so return the "default" FormDefinition for the role (if any)
      scope = Hmis::Form::Definition.with_role(role).published
      # Only consider forms that have an active "default" rule, meaning there is no project criteria on the rule
      scope = scope.joins(:instances).merge(Hmis::Form::Instance.defaults.active)

      # Prefer forms with non-system rules.
      # (Handles case where there are two CLIENT forms that both have active default rules,
      #  but one of them is the default form and the other is custom)
      scope.order(fi_t[:system].asc, fd_t[:id].desc).first
    end

    # Raise an error if no definition was found for a system role (like CLIENT, PROJECT, etc).
    # System role forms are required for the HMIS to function. There should be system Instances that prevent this from happening.
    raise `No Definition found for System form #{role}` if role.to_sym.in?(SYSTEM_FORM_ROLES) && selected_definition.nil?

    selected_definition
  end

  def self.find_definition_for_service_type(service_type, project:)
    Hmis::Form::Definition.for_project(project: project, role: :SERVICE, service_type: service_type)
  end

  # Validate the JSON form content
  # Returns an array of HmisErrors::Error objects
  def validate_json_form
    # Skip validation of CustomDataElementDefinitions on draft form, because new CDEDs won't be created yet
    Hmis::Form::DefinitionValidator.perform(definition, role, skip_cded_validation: draft?)
  end

  def self.validate_schema(json)
    schema_path = Rails.root.
      join('drivers/hmis_external_apis/public/schemas/form_definition.json')
    HmisExternalApis::JsonValidator.perform(json, schema_path)
  end

  def hud_assessment?
    ASSESSMENT_FORM_ROLES.excluding(:CUSTOM_ASSESSMENT).include?(role.to_sym)
  end

  def intake?
    role.to_sym == :INTAKE
  end

  def exit?
    role.to_sym == :EXIT
  end

  def draft?
    status == DRAFT
  end

  def retired?
    status == RETIRED
  end

  def self.owner_class_for_role(role)
    return Hmis::Hud::CustomAssessment if ASSESSMENT_FORM_ROLES.include?(role.to_sym)

    return unless FORM_ROLE_CONFIG[role.to_sym].present?

    FORM_ROLE_CONFIG[role.to_sym][:owner_class].constantize
  end

  def owner_class
    self.class.owner_class_for_role(role)
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

  # validate form_values provides against the definition
  #   * errors & warnings on missing required fields
  #   * check if the input ids match the definition
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

  # Hash { link_id => FormItem }. Excludes group items
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

  # if the enrollment and project match
  def project_and_enrollment_match(...)
    instances.map { |i| i.project_and_enrollment_match(...) }.compact.min_by(&:rank)
  end

  # should use rails attr normalization in rails 7.1 (ActiveRecord::Base::normalizes)
  def external_form_object_key=(value)
    super(value.blank? ? nil : value.strip)
  end

  # Walk definition items either as open structs or hashes
  def walk_definition_nodes(as_open_struct: false, &block)
    if as_open_struct
      # yields each Item as an OpenStruct (easy access for read-only operations)
      definition_struct&.item&.each do |node|
        walk_definition_node_as_open_struct(node, &block)
      end
    else
      # yields each Item as a Hash (for mutating the items)
      definition.dig('item').each do |node|
        walk_definition_node_as_hash(node, &block)
      end
    end
  end

  protected def walk_definition_node_as_open_struct(node, &block)
    # if item has children, recur into them first
    node.item&.each { |child| walk_definition_node_as_open_struct(child, &block) }
    block.call(node)
  end

  protected def walk_definition_node_as_hash(node, &block)
    # if item has children, recur into them first
    node['item']&.each { |child| walk_definition_node_as_hash(child, &block) }
    block.call(node)
  end

  # Find and/or initialize CustomDataElementDefinitions that are collected by this form.
  # This is used by PublishExternalFormsJob.
  # This should eventually be removed as we're now moving towards relying on Publish Form to generate CDEDs.
  def introspect_custom_data_element_definitions(set_definition_identifier: false)
    owner_type = owner_class.sti_name
    raise "unable to determine owner class for form role: #{role}" unless owner_type

    data_source = GrdaWarehouse::DataSource.hmis.first # TODO: needs adjustment to support multiple data sources
    hud_user_id = Hmis::Hud::User.system_user(data_source_id: data_source.id).UserID
    cded_scope = Hmis::Hud::CustomDataElementDefinition.where(owner_type: owner_type, data_source: data_source)
    cdeds_by_key = cded_scope.index_by(&:key)

    cded_records = []
    walk_definition_nodes(as_open_struct: true) do |item|
      # Skip non-questions items (Groups and Display items)
      next if NON_QUESTION_ITEM_TYPES.include?(item.type)
      # Skip items that already map to a standard (HUD) field
      next if item.mapping&.field_name

      key = item.mapping&.custom_field_key
      # find CDED if it exists, or initialize a new one with defaults
      cded = cdeds_by_key[key] || cded_scope.new(key: key, UserID: hud_user_id)

      # Infer CDED attributes based on Item
      cded.owner_type = owner_type
      cded.field_type = self.class.infer_cded_field_type(item.type)
      cded.repeats = item.repeats || false

      # Infer label for CustomDataElementDefinition based on various labels
      cded.label = self.class.generate_cded_field_label(item)

      # If specified, set the definition identifier to specify that this CustomDataElementDefinition is ONLY collected by this form type.
      cded.form_definition_identifier = identifier if set_definition_identifier

      cded_records << cded
    end

    cded_records
  end

  # Helper for determining CustomDataElementDefinition attributes
  def self.infer_cded_field_type(item_type)
    case item_type
    when 'STRING', 'TEXT', 'CHOICE', 'TIME_OF_DAY', 'OPEN_CHOICE'
      'string'
    when 'BOOLEAN'
      'boolean'
    when 'DATE'
      'date'
    when 'INTEGER'
      'integer'
    when 'CURRENCY'
      'float'
    else
      raise "unable to determine cded type for #{item_type}"
    end
  end

  # Helper for determining CustomDataElementDefinition attributes
  def self.generate_cded_field_label(item)
    label = item.readonly_text.presence || item.brief_text.presence || item.text.presence || item.link_id.humanize
    ActionView::Base.full_sanitizer.sanitize(label)[0..100].strip
  end

  def set_hud_requirements
    changed = [] # list of Link IDs that were changed
    rule_module = HmisUtil::HudAssessmentFormRules2024.new

    walk_definition_nodes do |item|
      link_id = item['link_id']

      # Check if there is a required data collection rule for this link_id for this data collection stage (ie role)
      hud_rule = rule_module.hud_data_element_rule(role, link_id)
      if hud_rule
        # If the rule is different from what's on the item, update it
        difference = Hashdiff.diff(hud_rule, item['rule'], ignore_keys: '_comment')
        if difference.present?
          # puts "changing rule for #{link_id}: #{difference}"
          item['rule'] = hud_rule
          changed << link_id
        end
      end

      # Check if there is a "Data Collected About" requirement for this link_id for this data collection stage
      required_dca = rule_module.hud_data_element_data_collected_about(role, link_id)&.to_s
      if required_dca
        # Choose the less strict "data collected about". Examples:
        #   if HUD requires collection for 'HOH', but the form specifies 'HOH_AND_ADULTS', then leave it as-is (HOH_AND_ADULTS)
        #   if HUD requires collection for 'HOH_AND_ADULTS', but the form specifies it for 'HOH', "downgrade" the value to the less strict HUD value (HOH_AND_ADULTS)
        current_dca = item['data_collected_about']&.to_s
        chosen_dca = [required_dca, current_dca].compact_blank.min_by do |val|
          rank = Hmis::Form::InstanceEnrollmentMatch::MATCHES.find_index(val)
          raise "invalid data_collected_about: #{val}" if rank.nil?

          rank
        end

        if chosen_dca != current_dca
          # puts "changing data_collected_about for #{link_id}: (#{current_dca}=>#{chosen_dca})"
          item['data_collected_about'] = chosen_dca
          changed << link_id unless current_dca.blank? && chosen_dca == 'ALL_CLIENTS' # nil is functionally equivalent to ALL_CLIENTS, so don't consider it "changed"
        end
      end
    end
    changed
  end
end
