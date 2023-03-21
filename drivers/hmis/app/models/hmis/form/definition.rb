###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Definition < ::GrdaWarehouseBase
  self.table_name = :hmis_form_definitions
  include Hmis::Hud::Concerns::HasEnums

  has_many :instances, foreign_key: :definition_identifier, primary_key: :identifier
  has_many :custom_forms
  has_many :custom_service_types, through: :instances, foreign_key: :identifier, primary_key: :form_definition_identifier

  FORM_ROLES = {
    # Assessment forms
    INTAKE: 'Intake Assessment',
    UPDATE: 'Update Assessment',
    ANNUAL: 'Annual Assessment',
    EXIT: 'Exit Assessment',
    CE: 'Coordinated Entry',
    POST_EXIT: 'Post-Exit Assessment',
    CUSTOM: 'Custom Assessment',
    # Record-editing forms
    SERVICE: 'Service',
    PROJECT: 'Project',
    ORGANIZATION: 'Organization',
    CLIENT: 'Client',
    FUNDER: 'Funder',
    INVENTORY: 'Inventory',
    PROJECT_COC: 'Project CoC',
  }.freeze

  FORM_ROLE_CONFIG = {
    SERVICE: { class_name: 'Hmis::Hud::HmisService', permission: :can_edit_enrollments, resolve_as: 'Types::HmisSchema::Service' },
    PROJECT: { class_name: 'Hmis::Hud::Project', permission: :can_edit_project_details, resolve_as: 'Types::HmisSchema::Project' },
    ORGANIZATION: { class_name: 'Hmis::Hud::Organization', permission: :can_edit_organization, resolve_as: 'Types::HmisSchema::Organization' },
    CLIENT: { class_name: 'Hmis::Hud::Client', permission: :can_edit_clients, resolve_as: 'Types::HmisSchema::Client' },
    FUNDER: { class_name: 'Hmis::Hud::Funder', permission: :can_edit_project_details, resolve_as: 'Types::HmisSchema::Funder' },
    INVENTORY: { class_name: 'Hmis::Hud::Inventory', permission: :can_edit_project_details, resolve_as: 'Types::HmisSchema::Inventory' },
    PROJECT_COC: { class_name: 'Hmis::Hud::ProjectCoc', permission: :can_edit_project_details, resolve_as: 'Types::HmisSchema::ProjectCoc' },
  }.freeze

  FORM_DATA_COLLECTION_STAGES = {
    INTAKE: 1,
    UPDATE: 2,
    ANNUAL: 5,
    EXIT: 3,
    POST_EXIT: 6,
  }.freeze

  HUD_ASSESSMENT_FORM_ROLES = FORM_ROLES.slice(:INTAKE, :UPDATE, :ANNUAL, :EXIT, :CE, :POST_EXIT).freeze

  use_enum_with_same_key :form_role_enum_map, FORM_ROLES

  scope :for_project, ->(project) do
    instance_scope = Hmis::Form::Instance.none

    base_scope = Hmis::Form::Instance.joins(:definition)
    [
      base_scope.for_project(project.id),
      base_scope.for_organization(project.organization.id),
      base_scope.for_project_type(project.project_type),
      base_scope.defaults,
    ].each do |scope|
      next if instance_scope.present?

      instance_scope = scope unless scope.empty?
    end

    where(identifier: instance_scope.pluck(:definition_identifier))
  end

  scope :with_role, ->(role) { where(role: role) }

  def self.find_definition_for_role(role, project: nil, version: nil)
    scope = Hmis::Form::Definition.with_role(role)
    scope = scope.for_project(project) if project.present?
    scope = scope.where(version: version) if version.present?
    scope.order(version: :desc).first
  end

  # Validate JSON definition when loading, to ensure no duplicate link IDs
  def self.validate_json(json)
    seen_link_ids = Set.new

    recur_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']
        raise "Missing link ID: #{child_item}" unless link_id.present?

        raise "Duplicate link ID: #{link_id}" if seen_link_ids.include?(link_id)

        seen_link_ids.add(link_id)
        recur_check.call(child_item)
      end
    end

    recur_check.call(json)
  end

  def hud_assessment?
    HUD_ASSESSMENT_FORM_ROLES.keys.include?(role.to_sym)
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

  def record_editing_permission
    return unless FORM_ROLE_CONFIG[role.to_sym].present?

    FORM_ROLE_CONFIG[role.to_sym][:permission]
  end

  def assessment_date_item
    @assessment_date_item ||= link_id_item_hash.values.find(&:assessment_date)
  end

  def find_and_validate_assessment_date(values:, entry_date:, exit_date:)
    errors = HmisErrors::Errors.new
    date = nil
    item = assessment_date_item

    error_context = {
      readable_attribute: item.brief_text || item.text,
      link_id: item&.link_id,
    }

    if item.present? && values.present?
      date_string = values[item.link_id]

      if date_string.present?
        date = HmisUtil::Dates.safe_parse_date(date_string: date_string)
        errors.add item.field_name, :invalid, **error_context unless date.present?
      else
        errors.add item.field_name, :required, **error_context
      end
    elsif hud_assessment?
      errors.add :assessmentDate, :required, **error_context
    end

    return [nil, errors.errors] if errors.errors.any?

    # Additional validations for HUD assessment dates to be within appropriate entry/exit bounds
    if date.present? && hud_assessment?
      # Ensure assessment date is on or after entry date
      errors.add item.field_name, :out_of_range, **error_context, message: "must be after entry date (#{entry_date.strftime('%m/%d/%Y')})" if entry_date.present? && !intake? && date < entry_date
      # Ensure assessment date is on or before exit date
      errors.add item.field_name, :out_of_range, **error_context, message: "must be before exit date (#{exit_date.strftime('%m/%d/%Y')})" if exit_date.present? && !exit? && date > exit_date
    end

    date = nil if errors.errors.any?

    [date, errors.errors]
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

      is_missing = value.blank? || value == 'DATA_NOT_COLLECTED'

      # Validate required status
      if item.required && is_missing
        errors.add item.field_name || :base, :required, **error_context
      elsif item.warn_if_empty && is_missing
        errors.add item.field_name || :base, :data_not_collected, severity: :warning, **error_context
      end

      # Additional validations for currency
      errors.add item.field_name, :out_of_range, **error_context, message: 'must be positive' if item.type == 'CURRENCY' && value&.negative?

      # TODO(##184404620): Validate ValueBounds (How to handle bounds that rely on local values like projectStartDate and entryDate?)
      # TODO(##184402463): Add support for RequiredWhen
    end

    # Ensure all link IDs are in the FormDefinition
    form_values.each do |link_id, _|
      raise "Unrecognized link ID: #{link_id} for definition #{identifier}" unless link_id_item_hash.key?(link_id)
    end

    errors.errors
  end

  # Unused
  def key_by_field_name(hud_values)
    result = {}
    recur_fill = lambda do |items, current_record_type|
      items.each do |item|
        if item.item
          record_type = Types::Forms::Enums::RelatedRecordType.values[item.record_type]&.description if item.record_type.present?
          recur_fill.call(item.item, record_type || current_record_type)
        end

        next unless item.field_name.present?
        next unless hud_values.key?(item.link_id)

        key = item.field_name
        key = "#{current_record_type}.#{key}" if current_record_type.present?

        result[key] = hud_values[item.link_id]
      end
    end

    recur_fill.call(definition_struct.item, nil)
    result
  end

  private def definition_struct
    @definition_struct ||= Oj.load(definition, mode: :compat, object_class: OpenStruct)
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
