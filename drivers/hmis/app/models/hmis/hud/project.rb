###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Project < Hmis::Hud::Base
  include ::HmisStructure::Project
  include ::Hmis::Hud::Concerns::Shared
  include ActiveModel::Dirty

  has_paper_trail(meta: { project_id: :id })

  self.table_name = :Project
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  CONFIDENTIAL_PROJECT_NAME = 'Confidential Project'.freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :organization, **hmis_relation(:OrganizationID, 'Organization')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :projects

  # Affiliations to residential projects. This should only be present if this project is SSO or RRH Services Only.
  has_many :affiliations, **hmis_relation(:ProjectID, 'Affiliation'), inverse_of: :project
  # Affiliations to SSO/RRH SSO projects. This should only be present if this project is residential.
  # NOTE: you can't use hmis_relation for residential project, the keys don't match
  has_many :residential_affiliations, class_name: 'Hmis::Hud::Affiliation', primary_key: ['ProjectID', :data_source_id], foreign_key: ['ResProjectID', :data_source_id]

  # Affiliated SSO/RRH SSO projects
  has_many :affiliated_projects, through: :residential_affiliations, source: :project
  # Affiliated residential projects
  has_many :residential_projects, through: :affiliations

  has_many :hmis_participations, **hmis_relation(:ProjectID, 'HmisParticipation'), inverse_of: :project, dependent: :destroy
  has_many :ce_participations, **hmis_relation(:ProjectID, 'CeParticipation'), inverse_of: :project, dependent: :destroy
  # Enrollments in this Project, including WIP Enrollments
  has_many :enrollments, foreign_key: :project_pk, inverse_of: :project, dependent: :destroy, class_name: 'Hmis::Hud::Enrollment'

  has_many :project_cocs, **hmis_relation(:ProjectID, 'ProjectCoc'), inverse_of: :project, dependent: :destroy
  has_many :inventories, **hmis_relation(:ProjectID, 'Inventory'), inverse_of: :project, dependent: :destroy
  has_many :funders, **hmis_relation(:ProjectID, 'Funder'), inverse_of: :project, dependent: :destroy
  has_many :units, -> { active }, dependent: :destroy
  has_many :unit_type_mappings, dependent: :destroy, class_name: 'Hmis::ProjectUnitTypeMapping'

  has_many :group_viewable_entity_projects
  has_many :group_viewable_entities, through: :group_viewable_entity_projects, source: :group_viewable_entity

  has_many :households, foreign_key: :project_pk, inverse_of: :project
  has_many :custom_assessments, through: :enrollments
  has_many :services, through: :enrollments
  has_many :custom_services, through: :enrollments
  has_many :clients, through: :enrollments
  has_many :hmis_services, through: :enrollments

  has_one :warehouse_project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: :id, primary_key: :id

  accepts_nested_attributes_for :affiliations, allow_destroy: true

  has_and_belongs_to_many :project_groups,
                          class_name: 'GrdaWarehouse::ProjectGroup',
                          join_table: :project_project_groups

  validates_with Hmis::Hud::Validators::ProjectValidator

  # hide previous declaration of :viewable_by, we'll use this one
  # Includes any HMIS projects where the user has the can_view_projects permission
  replace_scope :viewable_by, ->(user) do
    ids = user.viewable_projects.pluck(:id)
    ids += user.viewable_organizations.joins(:projects).pluck(p_t[:id])
    ids += user.viewable_data_sources.joins(:projects).pluck(p_t[:id])

    where(id: ids, data_source_id: user.hmis_data_source_id)
  end

  # Includes any HMIS projects where the user has the specified permission(s)
  # NOTE: Pass kwarg "mode: 'all'" if all permissions must be present. Default is 'any'.
  #
  # WARNING! This will include projects that the user does not have access to view (e.g. they lack can_view_projects)
  scope :with_access, ->(user, *permissions, **kwargs) do
    ids = user.entities_with_permissions(Hmis::Hud::Project, *permissions, **kwargs).pluck(:id)
    ids += user.entities_with_permissions(Hmis::Hud::Organization, *permissions, **kwargs).joins(:projects).pluck(p_t[:id])
    ids += user.entities_with_permissions(GrdaWarehouse::DataSource, *permissions, **kwargs).joins(:projects).pluck(p_t[:id])

    where(id: ids, data_source_id: user.hmis_data_source_id)
  end

  scope :with_organization_ids, ->(organization_ids) do
    joins(:organization).where(o_t[:id].in(Array.wrap(organization_ids)))
  end

  # Always use ProjectType, we shouldn't need overrides since we can change the source data
  scope :with_project_type, ->(project_types) do
    where(ProjectType: project_types)
  end

  scope :with_funders, ->(funders) do
    joins(:funders).where(f_t[:funder].in(funders))
  end

  scope :open_on_date, ->(date = Date.current) do
    on_or_after_start = p_t[:operating_start_date].lteq(date)
    on_or_before_end = p_t[:operating_end_date].eq(nil).or(p_t[:operating_end_date].gteq(date))
    where(on_or_after_start.and(on_or_before_end))
  end

  scope :closed_on_date, ->(date = Date.current) do
    where(p_t[:operating_end_date].lt(date).or(p_t[:operating_start_date].gt(date)))
  end

  scope :with_statuses, ->(statuses) do
    return self if statuses.include?('OPEN') && statuses.include?('CLOSED')
    return open_on_date(Date.current) if statuses.include?('OPEN')
    return closed_on_date(Date.current) if statuses.include?('CLOSED')

    self
  end

  scope :matching_search_term, ->(search_term) do
    return none unless search_term.present?

    search_term.strip!
    query = "%#{search_term.split(/\W+/).join('%')}%"
    where(p_t[:ProjectName].matches(query).or(p_t[:id].eq(search_term)).or(p_t[:project_id].eq(search_term)))
  end

  SORT_OPTIONS = [:organization_and_name, :name].freeze

  SORT_OPTION_DESCRIPTIONS = {
    organization_and_name: 'Organization and Name',
    name: 'Name',
  }.freeze

  HudUtility2024.residential_project_type_numbers_by_code.each do |k, v|
    scope k, -> { where(project_type: v) }
    define_method "#{k}?" do
      v.include? project_type
    end
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :name
      order(:ProjectName)
    when :organization_and_name
      joins(:organization).order(o_t[:OrganizationName], p_t[:ProjectName])
    else
      raise NotImplementedError
    end
  end

  def self.apply_filters(input)
    Hmis::Filter::ProjectFilter.new(input).filter_scope(self)
  end

  def active
    return true unless operating_end_date.present?

    operating_end_date >= Date.current
  end

  def name
    project_name
  end

  def close_related_funders_and_inventory!
    funders.where(end_date: nil).update_all(end_date: operating_end_date)
    inventories.where(inventory_end_date: nil).update_all(inventory_end_date: operating_end_date)
  end

  def to_pick_list_option
    {
      code: id,
      label: project_name,
      secondary_label: HudUtility2024.project_type_brief(project_type),
      group_label: organization.organization_name,
      group_code: organization.id,
    }
  end

  # Data Collection Features that are enabled for this project (e.g. Current Living Situation)
  #
  # Is it enabled?
  #   If ANY instances exist for it for this project, even inactive ones, then yes.
  #
  # Who is data collected about?
  #   Choose the "best" instance – IE the one that would actually be selected
  #   when creating a new record – and return the data_collected_about on it.
  #
  # Returns an OpenStruct that is resolved by the DataCollectionFeature GQL type.
  def data_collection_features
    # Create OpenStruct for each enabled feature
    Hmis::Form::Definition::DATA_COLLECTION_FEATURE_ROLES.map do |role|
      base_scope = Hmis::Form::Instance.with_role(role)
      # Service instances must specify a service type or category.
      base_scope = base_scope.for_services if role == :SERVICE

      # Choose the "best" instance, i.e. the one that would actually be selected when recording new data.
      # We need to do this so that we can accurately set "data collected about" based on the most applicable form.
      #
      # If there are no active instances, but there are IN-active ones, then choose the best out of the inactives.
      # Inactive features need to continue to be "turned on" in order to view and edit legacy data.
      # If/when there is no legacy data, the instance can be fully deleted.

      best_instance = [
        base_scope.active,
        base_scope.inactive,
      ].lazy.map { |scope| scope.order(updated_at: :desc).detect_best_instance_for_project(project: self) }.detect(&:present?)
      next unless best_instance

      OpenStruct.new(
        role: role.to_s,
        id: [id, best_instance.id].join(':'), # Unique ID for Apollo caching
        legacy: best_instance.active == false,
        data_collected_about: best_instance.data_collected_about || 'ALL_CLIENTS',
        instance: best_instance, # just for testing
      )
    end.compact
  end

  # Service types that are collected in this project. They are collected if they have an active form definition and instance.
  def available_service_types
    # Find form rules for services that are applicable to this project
    ids = Hmis::Form::Instance.for_services.
      active.
      for_project_through_entities(self).
      joins(:definition).
      where(fd_t[:role].eq(:SERVICE)).
      pluck(:custom_service_type_id, :custom_service_category_id)

    type_matches = cst_t[:id].in(ids.map(&:first))
    category_matches = cst_t[:custom_service_category_id].in(ids.map(&:last))

    Hmis::Hud::CustomServiceType.where(type_matches.or(category_matches))
  end

  # Occurrence Point Form Instances that are enabled for this project (e.g. Move In Date form)
  def occurrence_point_form_instances
    # All instances for Occurrence Point forms
    base_scope = Hmis::Form::Instance.with_role(:OCCURRENCE_POINT).active

    # All possible form identifiers used for Occurrence Point collection
    occurrence_point_identifiers = base_scope.pluck(:definition_identifier).uniq

    # Choose the most specific instance for each definition identifier
    occurrence_point_identifiers.map do |identifier|
      scope = base_scope.where(definition_identifier: identifier).order(updated_at: :desc)
      scope.detect_best_instance_for_project(project: self)
    end.compact
  end

  include RailsDrivers::Extensions
end
