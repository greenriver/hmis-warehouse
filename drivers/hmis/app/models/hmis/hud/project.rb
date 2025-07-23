###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

class Hmis::Hud::Project < Hmis::Hud::Base
  self.table_name = :Project
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::Project
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::FormSubmittable
  include ActiveModel::Dirty

  has_paper_trail(meta: { project_id: :id })

  CONFIDENTIAL_PROJECT_NAME = 'Confidential Project'.freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :organization, **hmis_relation(:OrganizationID, 'Organization')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :projects

  # Affiliations to residential projects. This should only be present if this project is SSO or RRH Services Only.
  has_many :affiliations, **hmis_relation(:ProjectID, 'Affiliation'), inverse_of: :project
  # Affiliations to SSO/RRH SSO projects. This should only be present if this project is residential.
  # NOTE: you can't use hmis_relation for residential project, the keys don't match
  has_many :residential_affiliations, class_name: 'Hmis::Hud::Affiliation', primary_key: ['ProjectID', :data_source_id], query_constraints: ['ResProjectID', :data_source_id]

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
  has_many :unit_groups, dependent: :destroy, class_name: 'Hmis::UnitGroup'
  has_many :unit_type_mappings, dependent: :destroy, class_name: 'Hmis::ProjectUnitTypeMapping'

  has_many :group_viewable_entity_projects
  has_many :group_viewable_entities, through: :group_viewable_entity_projects, source: :group_viewable_entity

  has_many :households, foreign_key: :project_pk, inverse_of: :project
  has_many :custom_assessments, through: :enrollments
  has_many :services, through: :enrollments
  has_many :custom_services, through: :enrollments
  has_many :clients, through: :enrollments
  has_many :hmis_services, through: :enrollments
  has_many :current_living_situations, through: :enrollments
  has_many :project_staff_assignment_configs, class_name: 'Hmis::ProjectStaffAssignmentConfig'
  has_many :ce_opportunities, class_name: 'Hmis::Ce::Opportunity', foreign_key: :project_id, dependent: :destroy, inverse_of: :project
  has_many :ce_referrals, class_name: 'Hmis::Ce::Referral', through: :ce_opportunities, source: :referrals

  has_one :warehouse_project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: :id, primary_key: :id

  accepts_nested_attributes_for :affiliations, allow_destroy: true

  has_and_belongs_to_many :project_groups,
                          class_name: 'Hmis::ProjectGroup',
                          join_table: :hmis_project_project_groups,
                          association_foreign_key: 'hmis_project_group_id'

  validates_with Hmis::Hud::Validators::ProjectValidator

  # hide previous declaration of :viewable_by, we'll use this one
  # Includes any HMIS projects where the user has the can_view_projects permission
  replace_scope :viewable_by, ->(user) do
    ids = user.viewable_projects.pluck(:id)
    ids += user.viewable_organizations.joins(:projects).pluck(p_t[:id])
    ids += user.viewable_project_groups.joins(:projects).pluck(p_t[:id])
    ids += user.viewable_data_sources.joins(:projects).pluck(p_t[:id])

    where(id: ids, data_source_id: user.hmis_data_source_id)
  end

  # Includes any HMIS projects where the user has the specified permission(s)
  # NOTE: Pass kwarg "mode: :all" if all permissions must be present. Default is 'any'.
  #
  # WARNING! This will include projects that the user does not have access to view (e.g. they lack can_view_projects)
  scope :with_access, ->(user, *permissions, **kwargs) do
    ids = user.entities_with_permissions(Hmis::Hud::Project, *permissions, **kwargs).pluck(:id)
    ids += user.entities_with_permissions(Hmis::Hud::Organization, *permissions, **kwargs).joins(:projects).pluck(p_t[:id])
    ids += user.entities_with_permissions(Hmis::ProjectGroup, *permissions, **kwargs).joins(:projects).pluck(p_t[:id])
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

    where(
      [
        p_t[:ProjectName].matches(query),
        p_t[:project_id].eq(search_term),
        possibly_pk?(search_term) ? p_t[:id].eq(search_term) : nil,
      ].compact.inject(&:or),
    )
  end

  scope :receiving_legacy_referrals, -> do
    # Find all active instances that enable the Referral functionality
    instance_scope = Hmis::Form::Instance.active.with_role(:REFERRAL).published
    # Find open projects that have an instance that match the criteria, which indicates that the
    # project accepts referrals.

    # We do not check `viewable_by` because providers can refer to projects they can't otherwise view.
    # NOTE: is not optimized, could be refactored if performance is an issue. Used this approach to minimize
    # duplication of project_match logic.
    referral_project_ids = Hmis::Hud::Project.open_on_date(Date.current).select do |project|
      instance_scope.any? { |instance| instance.project_match(project) }
    end.map(&:id)

    where(id: referral_project_ids)
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
      joins(:organization).order(o_t[:OrganizationName], p_t[:ProjectName], id: :desc)
    else
      raise NotImplementedError
    end
  end

  def self.apply_filters(input)
    Hmis::Filter::ProjectFilter.new(input).filter_scope(self)
  end

  def receives_legacy_referrals?
    Hmis::Form::Instance.active.published.with_role(:REFERRAL).any? { |instance| instance.project_match(self) }
  end

  def receives_direct_ce_referrals?
    config = Hmis::ProjectCeConfig.detect_best_config_for_project(self)

    return false unless config.present?
    return false unless config.receives_direct_referrals?

    true
  end

  def receives_direct_ce_referrals_from?(source_project)
    return false unless receives_direct_ce_referrals?

    config = Hmis::ProjectCeConfig.detect_best_config_for_project(self)
    # If the config specifies a list of projects that it accepts referrals from, check that this project is in that list.
    return false if config.receives_direct_referrals_from.present? && config.receives_direct_referrals_from.exclude?(source_project.id)

    true
  end

  def services_only_rrh?
    # Project Type PH-RRH (13) with RRHSubType 'RRH: Services Only' (1) indicate that the project only provides services
    project_type == 13 && rrh_sub_type == 1
  end

  # Whether Enrollments are allowed to have EntryDate==ExitDate in this project.
  # HUD specifies that certain Residential projects do not allow same-day exits.
  def allows_same_day_exit?
    if services_only_rrh?
      true # RRH-Services-Only projects allow same-day exit
    elsif HudUtility2024.residential_project_type_ids.include?(project_type)
      false # Residential projects do not allow same-day exit
    else
      true # Non-residential projects allow same-day exit
    end
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
  #   If ANY data exists for it in this project, even if no active instances exist, then yes.
  #   (This supports both inactive instances and migrated-in data, as well as context changes such as change in HoH)
  #
  # Who is data collected about?
  #   Choose the "best" instance – IE the one that would actually be selected
  #   when creating a new record – and return the data_collected_about on it.
  #
  # Returns an OpenStruct that is resolved by the DataCollectionFeature GQL type.
  def data_collection_features
    # Create OpenStruct for each enabled feature
    Hmis::Form::Definition::DATA_COLLECTION_FEATURE_ROLES.map do |role|
      instance_scope = Hmis::Form::Instance.with_role(role).active.published
      # Service instances must specify a service type or category.
      instance_scope = instance_scope.for_services if role == :SERVICE

      # Choose the "best" instance, i.e. the one that would actually be selected when recording new data.
      # We need to do this so that we can accurately set "data collected about" based on the most applicable form.
      best_instance = instance_scope.detect_best_instance_for_project(project: self)

      # (Side note: For SERVICE specifically, there's really no such thing as a "best" instance in this context
      # without a service type. As long as there is ANY instance, the data collection feature is enabled. But we don't
      # need to worry about the fact that "best" instance chosen here might not actually be the most specific.)

      has_any_data = case role
      when :CURRENT_LIVING_SITUATION
        current_living_situations.exists?
      when :SERVICE
        custom_services.exists? || services.exists?
      when :CE_EVENT
        false # Only resolved on enrollments. Would need to update this logic if we resolve CE events on projects
      when :CE_ASSESSMENT
        false # Only resolved on enrollments. Would need to update this logic if we resolve CE assessments on projects
      when :CASE_NOTE
        false # Only resolved on enrollments. Would need to update this logic if we resolve case notes on projects
      when :REFERRAL
        # Referrals are a special case, the Data Collection Feature is not really used in the frontend. Appearance of
        # this feature is gated based on permission instead. However, just for consistency we still return has_any_data
        external_referral_postings.exists?
      when :REFERRAL_REQUEST
        external_referral_requests.exists? # Also a special case, see above
      when :EXTERNAL_FORM
        false # Relies on instances only; see comment in HmisSchema::Project.external_form_submissions
      else
        raise "Unexpected data collection feature role: #{role}"
      end

      next unless best_instance || has_any_data

      OpenStruct.new(
        role: role.to_s,
        id: [id, role, best_instance&.id].join(':'), # Unique ID for Apollo caching
        legacy: has_any_data && !best_instance,
        data_collected_about: best_instance&.data_collected_about || 'ALL_CLIENTS', # Doesn't really matter for legacy
        instance: best_instance, # just for testing
      )
    end.compact
  end

  def staff_assignments_enabled?
    Hmis::ProjectStaffAssignmentConfig.detect_best_config_for_project(self).present?
  end

  def should_auto_enter?
    Hmis::ProjectAutoEnterConfig.detect_best_config_for_project(self).present?
  end

  def auto_exit_enabled?
    Hmis::ProjectAutoExitConfig.detect_best_config_for_project(self).present?
  end

  def auto_exit_days_threshold
    config = Hmis::ProjectAutoExitConfig.detect_best_config_for_project(self)
    config&.length_of_absence_days
  end

  def coordinated_entry_enabled?
    # Override to false if the system-wide AppConfigProperty is disabled
    return false unless Hmis::Ce.configuration.enabled?

    Hmis::ProjectCeConfig.detect_best_config_for_project(self).present?
  end

  # Service types that are collected in this project. They are collected if they have an active form definition and instance.
  def available_service_types
    # Find form rules for services that are applicable to this project
    ids = Hmis::Form::Instance.for_services.
      active.
      for_project_through_entities(self).
      joins(:definition).
      where(fd_t[:role].eq(:SERVICE).and(fd_t[:status].eq(Hmis::Form::Definition::PUBLISHED))).
      pluck(:custom_service_type_id, :custom_service_category_id)

    type_matches = cst_t[:id].in(ids.map(&:first))
    category_matches = cst_t[:custom_service_category_id].in(ids.map(&:last))

    Hmis::Hud::CustomServiceType.where(type_matches.or(category_matches))
  end

  # Occurrence Point Form Instances that are enabled for this project (e.g. Move In Date form)
  def occurrence_point_form_instances
    Hmis::Form::OccurrencePointFormCollection.new.for_project(self)
  end

  def uniq_coc_codes
    @uniq_coc_codes ||= project_cocs.pluck(:CoCCode).uniq.compact_blank.sort
  end

  # Determine and validate CoC Code, which is needed for creating new Enrollments
  def determine_coc_code(coc_code_arg:)
    # If project has exactly 1 CoC code, always use that
    return uniq_coc_codes.first if uniq_coc_codes.size == 1

    raise 'CoC Code required for project' unless coc_code_arg
    raise "Invalid CoC Code #{coc_code_arg} for project" unless uniq_coc_codes.include?(coc_code_arg)

    coc_code_arg
  end

  include RailsDrivers::Extensions
end
