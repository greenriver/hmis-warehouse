###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Specifies which polymorphic entity (and/or service type) that a given form is applicable to.
class Hmis::Form::Instance < ::GrdaWarehouseBase
  include Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_form_instances

  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :definition, -> { where(status: 'published') }, foreign_key: :definition_identifier, primary_key: :identifier, class_name: 'Hmis::Form::Definition'

  belongs_to :custom_service_category, optional: true, class_name: 'Hmis::Hud::CustomServiceCategory'
  belongs_to :custom_service_type, optional: true, class_name: 'Hmis::Hud::CustomServiceType'

  validates :data_collected_about, inclusion: { in: Types::Forms::Enums::DataCollectedAbout.values.keys }, allow_blank: true
  validates :funder, inclusion: { in: HudUtility2024.funding_sources.keys }, allow_blank: true
  validates :project_type, inclusion: { in: HudUtility2024.project_types.keys }, allow_blank: true
  validate :validate_external_form_restrictions

  # 'system' instances can't be deleted
  scope :system, -> { where(system: true) }
  scope :not_system, -> { where(system: false) }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  scope :for_projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
  scope :for_organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
  scope :defaults, -> do
                     where(
                       entity_type: nil,
                       entity_id: nil,
                       funder: nil,
                       other_funder: nil,
                       project_type: nil,
                     )
                   end

  scope :with_role, ->(role) { joins(:definition).where(fd_t[:role].in(role)) }

  # Find instances that are for a specific Project
  scope :for_project, ->(project_id) { for_projects.where(entity_id: project_id) }

  # Find instances that are for a specific Organization
  scope :for_organization, ->(organization_id) { for_organizations.where(entity_id: organization_id) }

  # Find instances that are for a Service Type
  scope :for_service_type, ->(service_type_id) { where(custom_service_type_id: service_type_id) }
  # Find instances that are for a Service Category
  scope :for_service_category, ->(category_id) { where(custom_service_category_id: category_id) }
  # Find all instances for a given Service Category, including those specified by type
  scope :for_service_category_by_entities, ->(category_id) do
    service_type_ids = Hmis::Hud::CustomServiceType.where(custom_service_category_id: category_id).pluck(:id)

    where(fi_t[:custom_service_category_id].in(Array.wrap(category_id)).or(fi_t[:custom_service_type_id].in(service_type_ids)))
  end

  # Find instances that are specified by service type or service category
  scope :for_services, -> do
    where(fi_t[:custom_service_type_id].not_eq(nil).or(fi_t[:custom_service_category_id].not_eq(nil)))
  end

  scope :not_for_services, -> do
    where(fi_t[:custom_service_type_id].eq(nil).and(fi_t[:custom_service_category_id].eq(nil)))
  end

  scope :for_project_through_entities, ->(project) do
    ids = all.map { |i| i.project_match(project) ? i.id : nil }.compact
    where(id: ids)
  end

  SORT_OPTIONS = [:form_title, :form_type, :date_updated].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :form_title
      joins(:definition).order(fd_t[:title])
    when :form_type
      joins(:definition).order(fd_t[:role])
    when :date_updated
      order(updated_at: :desc)
    else
      raise NotImplementedError
    end
  end

  def validate_external_form_restrictions
    return unless definition.role.to_s == 'EXTERNAL_FORM'

    # External forms can only have Project-level rules, because they are not meant to be reviewed in multiple projects
    errors.add(:base, :invalid, full_message: 'External forms only support rule specification by Project') if entity_type != 'Hmis::Hud::Project'
    # External forms can only have ONE active Project-level rule
    errors.add(:base, :invalid, full_message: 'External forms can only have one active rule') if new_record? && definition.instances.active.for_projects.exists?
  end

  def project_matches(project_scope)
    project_scope.map { |project| project_match(project) }.compact
  end

  def self.apply_filters(input)
    Hmis::Filter::FormInstanceFilter.new(input).filter_scope(self)
  end

  def self.detect_best_instance_for_project(project:)
    matches = all.map { |i| i.project_match(project) }.compact
    # with_index for stable sort
    matches.sort_by.with_index { |match, idx| [match.rank, idx] }.first&.instance
  end

  def project_match(project)
    match = Hmis::Form::InstanceProjectMatch.new(instance: self, project: project)
    match.valid? ? match : nil
  end

  # if the enrollment and project match
  def project_and_enrollment_match(project:, enrollment:)
    enrollment_match = Hmis::Form::InstanceEnrollmentMatch.new(instance: self, enrollment: enrollment)
    enrollment_match.valid? ? project_match(project) : nil
  end

  def to_pick_list_option
    { code: definition.identifier, label: definition.title }
  end
end
