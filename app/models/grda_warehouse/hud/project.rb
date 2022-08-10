###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# these are also sometimes called programs
module GrdaWarehouse::Hud
  class Project < Base
    include ArelHelper
    include HudSharedScopes
    include ProjectReport
    include ::HmisStructure::Project
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :Project
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    has_paper_trail

    include Filterable

    RESIDENTIAL_PROJECT_TYPES = {}.tap do |pt|
      h = { # duplicate of code in various places
        ph: [3, 9, 10, 13],
        rrh: [13],
        psh: [3, 10],
        oph: [9],
        th: [2],
        es: [1],
        so: [4],
        sh: [8],
      }
      pt.merge! h
      pt[:permanent_housing]    = h[:ph]
      pt[:transitional_housing] = h[:th]
      pt[:emergency_shelter]    = h[:es]
      pt[:street_outreach]      = h[:so]
      pt[:safe_haven]           = h[:sh]
      pt.freeze
    end.freeze

    HOMELESS_PROJECT_TYPE_CODES = [:es, :so, :sh, :th].freeze
    SPM_PROJECT_TYPE_CODES = [:es, :so, :sh, :th, :ph].freeze
    PATH_PROJECT_TYPE_CODES = [:so, :services_only].freeze

    RESIDENTIAL_PROJECT_TYPE_IDS = RESIDENTIAL_PROJECT_TYPES.values.flatten.uniq.sort

    CHRONIC_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh).flatten
    LITERALLY_HOMELESS_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh).flatten
    HOMELESS_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh, :th).flatten
    HOMELESS_SHELTERED_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :sh, :th).flatten
    HOMELESS_UNSHELTERED_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten

    PROJECT_GROUP_TITLES = {
      ph: 'Permanent Housing (PH, PSH, & RRH)',
      es: 'Emergency Shelter (ES)',
      th: 'Transitional Housing (TH)',
      sh: 'Safe Haven (SH)',
      so: 'Street Outreach (SO)',
      rrh: 'Rapid Re-Housing (RRH)',
      ca: 'Coordinated Entry (CE)',
      psh: 'Permanent Supportive Housing (PSH)',
      oph: 'Permanent Housing Only (OPH)',
      other: 'Other',
      day_shelter: 'Day Shelter',
      prevention: 'Homelessness Prevention',
      services_only: 'Services Only',
    }.freeze
    PROJECT_TYPE_TITLES = PROJECT_GROUP_TITLES.select { |k, _| k.in?([:ph, :es, :th, :sh, :so]) }.freeze
    HOMELESS_TYPE_TITLES = PROJECT_TYPE_TITLES.except(:ph)
    CHRONIC_TYPE_TITLES = PROJECT_TYPE_TITLES.except(:ph)
    RESIDENTIAL_TYPE_TITLES = PROJECT_GROUP_TITLES.select { |k, _| k.in?([:ph, :es, :th, :sh, :so, :rrh, :psh, :oph]) }.freeze
    PROJECT_TYPE_COLORS = {
      ph: 'rgba(150, 3, 130, 0.5)',
      th: 'rgba(103, 81, 140, 0.5)',
      es: 'rgba(87, 132, 93, 0.5)',
      so: 'rgba(132, 26, 7, 0.5)',
      sh: 'rgba(61, 99, 130, 0.5)',
    }.freeze

    ALL_PROJECT_TYPES = ::HUD.project_types.keys
    PROJECT_TYPES_WITHOUT_INVENTORY = [4, 6, 7, 11, 12, 14].freeze
    PROJECT_TYPES_WITH_INVENTORY = ALL_PROJECT_TYPES - PROJECT_TYPES_WITHOUT_INVENTORY
    WITH_MOVE_IN_DATES = RESIDENTIAL_PROJECT_TYPES[:ph]
    PERFORMANCE_REPORTING = { # duplicate of code in various places
      ph: [3, 9, 10, 13],
      oph: [9],
      th: [2],
      es: [1],
      so: [4],
      sh: [8],
      ca: [14],
      rrh: [13],
      psh: [3, 10],
      other: [7],
      day_shelter: [11],
      prevention: [12],
      services_only: [6],
    }.freeze

    attr_accessor :hud_coc_code, :geocode_override, :geography_type_override, :zip_override
    belongs_to :organization, **hud_assoc(:OrganizationID, 'Organization'), inverse_of: :projects, optional: true
    belongs_to :data_source, inverse_of: :projects
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :projects, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :projects, optional: true

    has_and_belongs_to_many :project_groups,
                            class_name: 'GrdaWarehouse::ProjectGroup',
                            join_table: :project_project_groups

    has_many :service_history_enrollments, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: [:data_source_id, :ProjectID, :OrganizationID], foreign_key: [:data_source_id, :project_id, :organization_id]
    has_many :service_history_services, through: :service_history_enrollments

    has_many :project_cocs, **hud_assoc(:ProjectID, 'ProjectCoc'), inverse_of: :project
    has_many :geographies, **hud_assoc(:ProjectID, 'Geography'), inverse_of: :project
    has_many :enrollments, **hud_assoc(:ProjectID, 'Enrollment'), inverse_of: :project
    has_many :income_benefits, through: :enrollments, source: :income_benefits
    has_many :disabilities, through: :enrollments, source: :disabilities
    has_many :employment_educations, through: :enrollments, source: :employment_educations
    has_many :health_and_dvs, through: :enrollments, source: :health_and_dvs
    has_many :services, through: :enrollments, source: :services
    has_many :exits, through: :enrollments, source: :exit
    # has_many :inventories, through: :project_cocs, source: :inventories
    has_many :inventories, **hud_assoc(:ProjectID, 'Inventory'), inverse_of: :project
    has_many :clients, through: :enrollments, source: :client
    has_many :funders, **hud_assoc(:ProjectID, 'Funder'), inverse_of: :project

    has_many :affiliations, **hud_assoc(:ProjectID, 'Affiliation'), inverse_of: :project
    # NOTE: you can't use hud_assoc for residential project, the keys don't match
    has_many :residential_affiliations, class_name: 'GrdaWarehouse::Hud::Affiliation', primary_key: ['ProjectID', :data_source_id], foreign_key: ['ResProjectID', :data_source_id]

    has_many :affiliated_projects, through: :residential_affiliations, source: :project
    has_many :residential_projects, through: :affiliations

    has_many :enrollment_cocs, **hud_assoc(:ProjectID, 'EnrollmentCoc'), inverse_of: :project

    # Warehouse Reporting
    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_one :current_data_quality_report, -> do
      where(processing_errors: nil).where.not(completed_at: nil).order(created_at: :desc).limit(1)
    end, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_many :contacts, class_name: 'GrdaWarehouse::Contact::Project', foreign_key: :entity_id
    has_many :organization_contacts, through: :organization, source: :contacts

    # Setup an association to project_cocs that allows us to pull the records even if the
    # project_coc has been deleted
    belongs_to :project_cocs_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::ProjectCoc', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], optional: true

    scope :residential, -> do
      where(ProjectType: RESIDENTIAL_PROJECT_TYPE_IDS)
    end
    scope :hud_residential, -> do
      where(project_type_override.in(RESIDENTIAL_PROJECT_TYPE_IDS))
    end
    scope :non_residential, -> do
      where.not(ProjectType: RESIDENTIAL_PROJECT_TYPE_IDS)
    end
    scope :hud_non_residential, -> do
      where.not(project_type_override.in(RESIDENTIAL_PROJECT_TYPE_IDS))
    end

    scope :chronic, -> do
      where(project_type_override.in(CHRONIC_PROJECT_TYPES))
    end
    scope :hud_chronic, -> do
      where(project_type_override.in(CHRONIC_PROJECT_TYPES))
    end
    scope :homeless, -> do
      where(project_type_override.in(HOMELESS_PROJECT_TYPES))
    end
    scope :hud_homeless, -> do
      where(project_type_override.in(CHRONIC_PROJECT_TYPES))
    end
    scope :homeless_sheltered, -> do
      where(project_type_override.in(HOMELESS_SHELTERED_PROJECT_TYPES))
    end
    scope :homeless_unsheltered, -> do
      where(project_type_override.in(HOMELESS_UNSHELTERED_PROJECT_TYPES))
    end
    scope :residential_non_homeless, -> do
      r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      where(ProjectType: r_non_homeless)
    end
    scope :hud_residential_non_homeless, -> do
      r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      where(project_type_override.in(r_non_homeless))
    end

    scope :with_hud_project_type, ->(project_types) do
      where(project_type_override.in(project_types))
    end
    scope :with_project_type, ->(project_types) do
      where(project_type_column => project_types)
    end

    scope :in_coc, ->(coc_code:) do
      joins(:project_cocs).
        merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_code))
    end

    scope :night_by_night, -> do
      where(TrackingMethod: 3)
    end

    scope :confidential, -> do
      joins(:organization).where(p_t[:confidential].eq(true).or(o_t[:confidential].eq(true)))
    end

    scope :non_confidential, -> do
      joins(:organization).where(
        p_t[:confidential].eq(false).and(o_t[:confidential].eq(false)).
        or(p_t[:confidential].eq(nil).and(o_t[:confidential].eq(nil))),
      )
    end

    scope :coc_funded, -> do
      # hud_continuum_funded overrides ContinuumProject
      where(
        arel_table[:ContinuumProject].eq(1).
        and(arel_table[:hud_continuum_funded].eq(nil)).
        or(arel_table[:hud_continuum_funded].eq(true)),
      )
    end

    scope :enrollments_combined, -> do
      where(combine_enrollments: true)
    end

    scope :active_on, ->(date) do
      date = date.to_date
      active_during(date..date)
    end

    scope :active_during, ->(range) do
      start_date = cl(p_t[:operating_start_date_override], p_t[:OperatingStartDate])
      end_date = cl(p_t[:operating_end_date_override], p_t[:OperatingEndDate])
      where(
        end_date.gteq(range.first).or(end_date.eq(nil)).
        and(start_date.lteq(range.last).or(start_date.eq(nil))),
      )
    end

    def coc_funded?
      return self.ContinuumProject == 1 if hud_continuum_funded.nil?

      hud_continuum_funded
    end

    # NOTE: Careful, this returns duplicates as it joins inventories.
    # You may want to tack on a distinct, depending on what you need.
    scope :serves_families, -> do
      where(
        id: GrdaWarehouse::Hud::Project.joins(:inventories).
          merge(GrdaWarehouse::Hud::Inventory.serves_families).
          distinct.select(:id),
      )
    end

    def serves_families?
      if @serves_families.nil?
        @serves_families = self.class.serves_families.exists?(id)
      else
        @serves_families
      end
    end

    scope :serves_individuals, -> do
      where(
        p_t[:id].in(lit(GrdaWarehouse::Hud::Project.joins(:inventories).merge(GrdaWarehouse::Hud::Inventory.serves_individuals).select(:id).to_sql)).
          or(p_t[:id].not_in(lit(GrdaWarehouse::Hud::Project.serves_families.select(:id).to_sql))),
      )
    end

    def serves_individuals?
      if @serves_individuals.nil?
        @serves_individuals = self.class.serves_individuals.exists?(id)
      else
        @serves_individuals
      end
    end

    # NOTE: Careful, this returns duplicates as it joins inventories.
    # You may want to tack on a distinct, depending on what you need.
    scope :serves_individuals_only, -> do
      where.not(id: serves_families.select(:id))
    end
    def serves_only_individuals?
      if @serves_only_individuals.blank?
        @serves_only_individuals = self.class.serves_individuals_only.exists?(id)
      else
        @serves_only_individuals
      end
    end

    scope :serves_children, -> do
      joins(:inventories).merge(GrdaWarehouse::Hud::Inventory.serves_children)
    end
    def serves_children?
      self.class.serves_children.where(id: id).exists?
    end

    scope :overrides_homeless_active_status, -> do
      where(active_homeless_status_override: true)
    end

    scope :includes_verified_days_homeless, -> do
      where(include_in_days_homeless_override: true)
    end

    #################################
    # Standard Cohort Scopes
    scope :veteran, -> do
      where(id: joins(:clients).
        merge(GrdaWarehouse::Hud::Client.veteran).
        uniq.select(:id))
    end

    scope :non_veteran, -> do
      where(id: joins(:clients).
        merge(GrdaWarehouse::Hud::Client.non_veteran).
        uniq.select(:id))
    end

    scope :family, -> do
      serves_families
    end

    scope :individual, -> do
      serves_individuals
    end

    # End Standard Cohort Scopes
    #################################

    # A single scope to determine if a user can access a project within a particular context
    #
    # @param user [User] user viewing the project
    # @param project_scope [Symbol] a symbolized scope name that is merged into the vieable projects
    #   within the context of reporting project_scope is almost always non_confidential
    #   within the client dashboard context, project_scope is :all, which includes confidential projects
    #   names of confidential projects are obfuscated unless the user can_view_confidential_project_names
    scope :viewable_by, ->(user, confidential_scope_limiter: :non_confidential) do
      query = viewable_by_entity(user)
      # If a user can't report on confidential projects, exclude them entirely
      # return query if user.can_report_on_confidential_projects?
      return query if user.can_report_on_confidential_projects?

      query.send(confidential_scope_limiter)
    end

    scope :viewable_by_entity, ->(user) do
      quoted_column = ->(s) { connection.quote_column_name s }
      quoted_string = ->(s) { connection.quote s }

      where(
        [
          access_to_project_through_viewable_entities(user, quoted_string, quoted_column),
          access_to_project_through_organization(user, quoted_string, quoted_column),
          access_to_project_through_data_source(user, quoted_string, quoted_column),
          access_to_project_through_coc_codes(user, quoted_string, quoted_column),
          access_to_project_through_project_access_groups(user, quoted_string, quoted_column),
        ].join(' OR '),
      )
    end

    scope :editable_by, ->(user) do
      if user&.can_edit_projects?
        viewable_by(user)
      else
        none
      end
    end

    scope :overridden, -> do
      scope = where(Arel.sql('1=0'))
      override_columns.each_key do |col|
        scope = scope.or(where.not(col => nil))
      end
      scope
    end

    # If any of these are not blank, we'll consider it overridden
    def self.override_columns
      {
        act_as_project_type: :ProjectType,
        hud_continuum_funded: :ContinuumProject,
        housing_type_override: :HousingType,
        operating_start_date_override: :OperatingStartDate,
        operating_end_date_override: :OperatingEndDate,
        hmis_participating_project_override: :HMISParticipatingProject,
        target_population_override: :TargetPopulation,
        tracking_method_override: :TrackingMethod,
      }
    end

    def self.can_see_all_projects?(user)
      visible_count = viewable_by(user).distinct.count
      visible_count.positive? && visible_count == all.count
    end

    def self.access_to_project_through_viewable_entities(user, quoted_string, quoted_column)
      viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table     = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = Rails.cache.fetch([user, 'access_groups'], expires_in: 1.minutes) do
        user.access_groups.pluck(:id)
      end
      group_id_query = if group_ids.empty?
        '0=1'
      else
        "#{viewability_table}.#{quoted_column.call('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            WHERE
              #{viewability_table}.#{quoted_column.call('entity_id')}   = #{project_table}.#{quoted_column.call('id')}
              AND
              #{viewability_table}.#{quoted_column.call('entity_type')} = #{quoted_string.call(sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{quoted_column.call(viewability_deleted_column_name)} IS NULL
              AND
              #{project_table}.#{quoted_column.call(GrdaWarehouse::Hud::Project.paranoia_column)} IS NULL
        )

      SQL
    end

    def self.access_to_project_through_organization(user, quoted_string, quoted_column)
      viewability_table   = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table       = quoted_table_name
      organization_table  = GrdaWarehouse::Hud::Organization.quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = Rails.cache.fetch([user, 'access_groups'], expires_in: 1.minutes) do
        user.access_groups.pluck(:id)
      end
      group_id_query = if group_ids.empty?
        '0=1'
      else
        "#{viewability_table}.#{quoted_column.call('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            INNER JOIN
            #{organization_table}
            ON
              #{viewability_table}.#{quoted_column.call('entity_id')}   = #{organization_table}.#{quoted_column.call('id')}
              AND
              #{viewability_table}.#{quoted_column.call('entity_type')} = #{quoted_string.call(GrdaWarehouse::Hud::Organization.sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{quoted_column.call(viewability_deleted_column_name)} IS NULL
            WHERE
              #{organization_table}.#{quoted_column.call('data_source_id')} = #{project_table}.#{quoted_column.call('data_source_id')}
              AND
              #{organization_table}.#{quoted_column.call('OrganizationID')} = #{project_table}.#{quoted_column.call('OrganizationID')}
              AND
              #{organization_table}.#{quoted_column.call(GrdaWarehouse::Hud::Organization.paranoia_column)} IS NULL
        )

      SQL
    end

    def self.access_to_project_through_data_source(user, quoted_string, quoted_column)
      data_source_table = GrdaWarehouse::DataSource.quoted_table_name
      viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table     = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = Rails.cache.fetch([user, 'access_groups'], expires_in: 1.minutes) do
        user.access_groups.pluck(:id)
      end
      group_id_query = if group_ids.empty?
        '0=1'
      else
        "#{viewability_table}.#{quoted_column.call('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            INNER JOIN
            #{data_source_table}
            ON
              #{viewability_table}.#{quoted_column.call('entity_id')}   = #{data_source_table}.#{quoted_column.call('id')}
              AND
              #{viewability_table}.#{quoted_column.call('entity_type')} = #{quoted_string.call(GrdaWarehouse::DataSource.sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{quoted_column.call(viewability_deleted_column_name)} IS NULL
              AND
              #{data_source_table}.#{quoted_column.call(GrdaWarehouse::DataSource.paranoia_column)} IS NULL
            WHERE
              #{project_table}.#{quoted_column.call('data_source_id')} = #{data_source_table}.#{quoted_column.call('id')}
        )

      SQL
    end

    def self.access_to_project_through_coc_codes(user, quoted_string, quoted_column)
      return '(1=0)' unless user.coc_codes.any?

      project_coc_table = GrdaWarehouse::Hud::ProjectCoc.quoted_table_name
      project_table     = quoted_table_name

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{project_coc_table}
            INNER JOIN
            #{project_table} AS pt
            ON
              #{project_coc_table}.#{quoted_column[:ProjectID]}      = pt.#{quoted_column[:ProjectID]}
              AND
              #{project_coc_table}.#{quoted_column[:data_source_id]} = pt.#{quoted_column[:data_source_id]}
              AND
              #{project_coc_table}.#{quoted_column.call(GrdaWarehouse::Hud::ProjectCoc.paranoia_column)} IS NULL
            WHERE
              (
                (
                  #{project_coc_table}.#{quoted_column[:CoCCode]} IN (#{user.coc_codes.map { |c| quoted_string[c] }.join ','})
                  AND
                  (
                    #{project_coc_table}.#{quoted_column[:hud_coc_code]} IS NULL
                    OR
                    #{project_coc_table}.#{quoted_column[:hud_coc_code]} = ''
                  )
                )
                OR
                #{project_coc_table}.#{quoted_column[:hud_coc_code]} IN (#{user.coc_codes.map { |c| quoted_string[c] }.join ','})
              )
              AND
              #{project_table}.#{quoted_column[:id]} = pt.#{quoted_column[:id]}

        )

      SQL
    end

    def self.access_to_project_through_project_access_groups(user, _, _)
      return '(1=0)' unless user.project_access_groups.any?

      project_ids = Rails.cache.fetch([user, 'project_access_group_project_ids'], expires_in: 1.minutes) do
        user.project_access_groups.flat_map(&:projects).map(&:id)
      end
      p_t[:id].in(project_ids).to_sql
    end

    # make a scope for every project type and a type? method for instances
    RESIDENTIAL_PROJECT_TYPES.each do |k, v|
      scope k, -> { where(project_type_column => v) }
      define_method "#{k}?" do
        v.include? project_type_to_use
      end
    end

    scope :rrh, -> { where(project_type_column => PERFORMANCE_REPORTING[:rrh]) }
    def rrh?
      project_type_to_use.in?(PERFORMANCE_REPORTING[:rrh])
    end

    scope :psh, -> { where(project_type_column => PERFORMANCE_REPORTING[:psh]) }
    def psh?
      project_type_to_use.in?(PERFORMANCE_REPORTING[:psh])
    end

    def self.related_item_keys
      [:OrganizationID]
    end

    def self.project_type_override
      p_t[:computed_project_type]
      # cl(p_t[:act_as_project_type], p_t[:ProjectType])
    end

    def compute_project_type
      act_as_project_type.presence || self.ProjectType
    end

    # Originally wasn't PH, but is overridden to PH
    def project_type_overridden_as_ph?
      @psh_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
      ! @psh_types.include?(self.ProjectType) &&
        @psh_types.include?(compute_project_type)
    end

    alias_attribute :name, :ProjectName

    def confidential?
      super || GrdaWarehouse::Hud::Organization.confidential_org?(self.OrganizationID, data_source_id)
    end

    def confidential
      super || GrdaWarehouse::Hud::Organization.confidential_org?(self.OrganizationID, data_source_id)
    end

    # Get the name for this project, protecting confidential names if appropriate.
    # Confidential names are shown if the user has permission to view confidential projects
    # AND the project is in the user's project list.
    #
    # This should be used any time a project's name is being displayed in the app.
    #
    # The following views are EXCEPTIONS to the rule. They show confidential names regardless of user permission:
    # - HUD Reports
    # - Override Summary Report
    # - HMIS Cross Walks Report
    # - User Permission Report
    # - Project and Organizaton assignment for Users and Groups
    # - View Project page (because it already requires can_view_confidential_project_names)
    # - Edit Project page and other pages that require can_edit_projects (because users who can edit projects can change their confidentiality status)
    # - Edit Project Group
    # - Cohorts (Agency, Housing Search Agency, and Location)
    #
    # @param user [User] user viewing the project
    # @param include_project_type [Boolean] include the HUD project type in the name?
    # @param ignore_confidential_status [Boolean] always show confidential names, regardless of user access?
    def name(user = nil, include_project_type: false, ignore_confidential_status: false)
      project_name = if ignore_confidential_status || (user&.can_view_confidential_project_names? && user&.can_access_project?(self))
        self.ProjectName
      else
        safe_project_name
      end
      project_name += " (#{HUD.project_type_brief(computed_project_type)})" if include_project_type && computed_project_type.present?

      project_name
    end

    # Useful for confidentializing name after 'pluck'
    # The confidential parameter should indicate whether the Project or Organization is confidential
    def self.confidentialize_name(user, project_name, confidential)
      return project_name if user&.can_view_confidential_project_names?

      if confidential
        GrdaWarehouse::Hud::Project.confidential_project_name
      else
        project_name
      end
    end

    # Get the safe name for this project.
    def safe_project_name
      if confidential?
        self.class.confidential_project_name
      else
        self.ProjectName
      end
    end

    # Provide an organization name that is confidentialized in the same way as the project
    def organization_name(user = nil)
      return organization.class.confidential_organization_name if confidential? && (user.blank? || ! user.can_view_confidential_project_names?)

      organization.OrganizationName
    end

    def organization_and_name(user = nil, ignore_confidential_status: false)
      project_name = name(user, ignore_confidential_status: ignore_confidential_status)
      return "#{organization&.OrganizationName} / #{project_name}" if user&.can_view_confidential_project_names? || ignore_confidential_status

      return "#{organization&.OrganizationName} / #{project_name}" unless confidential?

      project_name
    end

    def name_and_type(ignore_confidential_status: false)
      name(include_project_type: true, ignore_confidential_status: ignore_confidential_status)
    end

    def self.project_names_for_coc coc_code
      in_coc(coc_code: coc_code).order(ProjectName: :asc).pluck(:ProjectName)
    end

    def bed_night_tracking?
      self.TrackingMethod == 3 || street_outreach_and_acts_as_bednight?
    end

    # Some Street outreach are counted like bed-night shelters, others aren't yet
    def street_outreach_and_acts_as_bednight?
      return false unless so?

      @answer ||= GrdaWarehouse::Hud::Project.where(id: id).
        joins(:services).
        select(:ProjectID, :data_source_id).
        where(Services: { RecordType: 12 }).
        exists?
      @answer
    end

    # generate a CSV file
    # there may be multiple lines per project
    def self.export_providers(coc_codes)
      spec = {
        hud_org_id: o_t[:OrganizationID],
        _hud_org_name: o_t[:OrganizationName],
        provider: p_t[:ProjectName],
        _provider: p_t[:ProjectID],
        hud_prog_type: p_t[project_type_column],
        fed_funding_source: f_t[:FunderID],
        fed_partner_program: f_t[:FunderID],
        grant_id: f_t[:GrantID],
        grant_start_date: f_t[:StartDate],
        grant_end_date: f_t[:EndDate],
        coc_code: pc_t[:CoCCode],
        hud_geocode: g_t[:Geocode],
        current_continuum_project: p_t[:ContinuumProject],
      }
      projects = joins(:funders, :organization, :project_cocs, :geographies).
        order(arel_table[:ProjectID], pc_t[:CoCCode], f_t[:FunderID]).
        where(pc_t[:CoCCode].in(coc_codes))
      spec.each do |header, selector|
        projects = projects.select selector.as(header.to_s)
      end

      CSV.generate headers: true do |csv|
        headers = spec.keys.reject { |k| k.to_s.starts_with? '_' }
        csv << headers

        last = nil
        connection.select_all(projects.to_sql).each do |project|
          row = []
          headers.each do |h|
            value = case h
            when :hud_org_id
              "#{project['_hud_org_name']} (#{project['hud_org_id']})".squish
            when :provider
              "#{project['provider']} (#{project['_provider']})".squish
            when :grant_start_date, :grant_end_date
              d = project[h.to_s].presence
              d && DateTime.parse(d).strftime('%Y-%m-%d %H:%M:%S')
            when :current_continuum_project
              ::HUD.ad_hoc_yes_no_1 project[h.to_s].presence&.to_i
            when :fed_partner_program
              ::HUD.funding_source project[h.to_s].presence&.to_i
            else
              project[h.to_s]
            end
            row << value
          end
          next if row == last

          last = row
          csv << row
        end
      end
    end

    def for_export
      row = HmisCsvTwentyTwentyTwo::Exporter::Project::Overrides.apply_overrides(self, options: { confidential: false })
      row = HmisCsvTwentyTwentyTwo::Exporter::Project.adjust_keys(row)
      row
    end

    def confidential_hint
      'If marked as confidential, the project name will be replaced with "Confidential Project" within individual client pages. Users with the "Can view confidential enrollment details" will still see the project name.'
    end

    def member_of_confidential_organization_hint
      'This project is part of a confidential organization.'
    end

    def combine_enrollments_hint
      'If enrollments are combined, the import process will collapse sequential enrollments for a given client at this project.'
    end

    # Sometimes all we have is a name, we still want to try and protect those.
    # This is not reliable! Use `name` or `confidentialize_name` methods whenever possible.
    def self.confidentialize_by_name_only(name:)
      # cache for a short amount of time to avoid multiple fetches
      @confidential_project_names = Rails.cache.fetch('confidential_project_names', expires_in: 1.minutes) do
        GrdaWarehouse::Hud::Project.where(confidential: true).
          pluck(:ProjectName).
          map(&:downcase).
          map(&:strip)
      end
      if @confidential_project_names.include?(name&.downcase&.strip)
        GrdaWarehouse::Hud::Project.confidential_project_name
      else
        name
      end
    end

    def self.confidential_project_name
      'Confidential Project'
    end

    def project_type_to_use
      self[self.class.project_type_column]
    end

    def self.project_type_column
      if GrdaWarehouse::Config.get(:project_type_override)
        :computed_project_type
      else
        :ProjectType
      end
    end

    def human_readable_project_type
      HUD.project_type(project_type_to_use)
    end

    def main_population
      if serves_families?
        'Family'
      elsif serves_children?
        'Children'
      else
        'Individuals'
      end
    end

    private def organization_source
      GrdaWarehouse::Hud::Organization
    end

    def self.text_search(text)
      return none unless text.present?

      query = "%#{text}%"

      org_matches = GrdaWarehouse::Hud::Organization.where(
        GrdaWarehouse::Hud::Organization.arel_table[:OrganizationID].eq(arel_table[:OrganizationID]).
        and(GrdaWarehouse::Hud::Organization.arel_table[:data_source_id].eq(arel_table[:data_source_id])),
      ).text_search(text).exists

      where(
        arel_table[:ProjectName].matches(query).
        or(org_matches),
      )
    end

    def self.options_for_select(user:, scope: nil)
      # don't cache this, it's a class method
      @options = begin
        options = {}
        project_scope = viewable_by(user)
        project_scope = project_scope.merge(scope) unless scope.nil?
        project_scope = project_scope.merge(non_confidential) unless user.can_view_confidential_project_names?

        project_scope.
          joins(:organization, :data_source).
          eager_load(:organization, :data_source).
          order(o_t[:OrganizationName].asc, ProjectName: :asc).
          each do |project|
            org_name = project.organization.OrganizationName
            org_name += " at #{project.data_source.short_name}" if Rails.env.development?
            options[org_name] ||= []
            text = project.name(user, include_project_type: true)
            # text += "#{project.ContinuumProject.inspect} #{project.hud_continuum_funded.inspect}"
            options[org_name] << [
              text,
              project.id,
            ]
          end
        options
      end
    end

    def destroy_dependents!
      # Find all PersonalIDs for this project, we'll use these later to clean up clients
      enrollment_ids = enrollments.distinct.pluck(:PersonalID)

      deleted_timestamp = Time.current
      # Inventory related
      project_cocs.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      geographies.update_all(DateDeleted: deleted_timestamp)
      inventories.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      funders.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      affiliations.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      residential_affiliations.update_all(DateDeleted: deleted_timestamp, source_hash: nil)

      # Client enrollment related
      income_benefits.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      disabilities.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      employment_educations.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      health_and_dvs.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      services.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      exits.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      enrollment_cocs.update_all(DateDeleted: deleted_timestamp, source_hash: nil)
      enrollments.update_all(DateDeleted: deleted_timestamp, source_hash: nil)

      # Remove any clients who no longer have any enrollments
      all_clients = []
      with_enrollments = []
      enrollment_ids.each_slice(1000) do |ids|
        all_clients += GrdaWarehouse::Hud::Client.
          where(data_source_id: data_source_id, PersonalID: ids).pluck(id)
        with_enrollments += GrdaWarehouse::Hud::Client.
          joins(:enrollments).
          where(data_source_id: data_source_id, PersonalID: ids).pluck(id)
      end
      no_enrollments = all_clients - with_enrollments
      GrdaWarehouse::Hud::Client.where(id: no_enrollments).update_all(DateDeleted: deleted_timestamp, source_hash: nil) if no_enrollments.present?

      destination_ids = GrdaWarehouse::WarehouseClient.where(source_id: all_clients).pluck(:destination_id)
      # Force reloads of client views
      GrdaWarehouse::Hud::Client.where(id: destination_ids).each(&:force_full_service_history_rebuild)
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
      destination_ids.each do |id|
        GrdaWarehouse::Hud::Client.clear_view_cache(id)
      end
    end
  end
end
