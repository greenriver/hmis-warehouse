###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# these are also sometimes called programs
module GrdaWarehouse::Hud
  class Project < Base
    include ArelHelper
    include HudSharedScopes
    include ProjectReport
    include ::HMIS::Structure::Project

    self.table_name = :Project
    self.hud_key = :ProjectID
    acts_as_paranoid column: :DateDeleted
    has_paper_trail

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :ProjectID,
          :OrganizationID,
          :ProjectName,
          :ProjectCommonName,
          :ContinuumProject,
          :ProjectType,
          :ResidentialAffiliation,
          :TrackingMethod,
          :TargetPopulation,
          :PITCount,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      when '6.11', '6.12'
        [
          :ProjectID,
          :OrganizationID,
          :ProjectName,
          :ProjectCommonName,
          :OperatingStartDate,
          :OperatingEndDate,
          :ContinuumProject,
          :ProjectType,
          :ResidentialAffiliation,
          :TrackingMethod,
          :TargetPopulation,
          :VictimServicesProvider,
          :HousingType,
          :PITCount,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :ProjectID,
          :OrganizationID,
          :ProjectName,
          :ProjectCommonName,
          :OperatingStartDate,
          :OperatingEndDate,
          :ContinuumProject,
          :ProjectType,
          :HousingType,
          :ResidentialAffiliation,
          :TrackingMethod,
          :HMISParticipatingProject,
          :TargetPopulation,
          :PITCount,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :ProjectID,
          :OrganizationID,
          :ProjectName,
          :ProjectCommonName,
          :OperatingStartDate,
          :OperatingEndDate,
          :ContinuumProject,
          :ProjectType,
          :ResidentialAffiliation,
          :TrackingMethod,
          :TargetPopulation,
          :VictimServicesProvider,
          :HousingType,
          :PITCount,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

   include Filterable

    RESIDENTIAL_PROJECT_TYPES = {}.tap do |pt|
      h = {   # duplicate of code in various places
        ph: [3,9,10,13],
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
    end

    RESIDENTIAL_PROJECT_TYPE_IDS = RESIDENTIAL_PROJECT_TYPES.values.flatten.uniq.sort

    CHRONIC_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh).flatten
    LITERALLY_HOMELESS_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh).flatten
    HOMELESS_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh, :th).flatten
    HOMELESS_SHELTERED_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :sh, :th).flatten
    HOMELESS_UNSHELTERED_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten

    PROJECT_TYPE_TITLES = {
        ph: 'Permanent Housing',
        es: 'Emergency Shelter',
        th: 'Transitional Housing',
        sh: 'Safe Haven',
        so: 'Street Outreach',
      }
    HOMELESS_TYPE_TITLES = PROJECT_TYPE_TITLES.except(:ph)
    CHRONIC_TYPE_TITLES = PROJECT_TYPE_TITLES.except(:ph)
    PROJECT_TYPE_COLORS = {
      ph: 'rgba(150, 3, 130, 0.5)',
      th: 'rgba(103, 81, 140, 0.5)',
      es: 'rgba(87, 132, 93, 0.5)',
      so: 'rgba(132, 26, 7, 0.5)',
      sh: 'rgba(61, 99, 130, 0.5)',
    }

    ALL_PROJECT_TYPES = ::HUD.project_types.keys
    PROJECT_TYPES_WITHOUT_INVENTORY = [4, 6, 7, 11, 12, 14]
    PROJECT_TYPES_WITH_INVENTORY = ALL_PROJECT_TYPES - PROJECT_TYPES_WITHOUT_INVENTORY
    WITH_MOVE_IN_DATES = RESIDENTIAL_PROJECT_TYPES[:ph] + RESIDENTIAL_PROJECT_TYPES[:th]

    attr_accessor :hud_coc_code, :geocode_override, :geography_type_override
    belongs_to :organization, **hud_assoc(:OrganizationID, 'Organization'), inverse_of: :projects
    belongs_to :data_source, inverse_of: :projects
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :projects, optional: true

    has_and_belongs_to_many :project_groups,
      class_name: GrdaWarehouse::ProjectGroup.name,
      join_table: :project_project_groups

    has_many :service_history_enrollments, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name, primary_key: [:data_source_id, :ProjectID, :OrganizationID], foreign_key: [:data_source_id, :project_id, :organization_id]

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

    scope :residential, -> do
      where(ProjectType: RESIDENTIAL_PROJECT_TYPE_IDS)
    end
    scope :hud_residential, -> do
      where(self.project_type_override.in(RESIDENTIAL_PROJECT_TYPE_IDS))
    end
    scope :non_residential, -> do
      where.not(ProjectType: RESIDENTIAL_PROJECT_TYPE_IDS)
    end
    scope :hud_non_residential, -> do
      where.not(self.project_type_override.in(RESIDENTIAL_PROJECT_TYPE_IDS))
    end

    scope :chronic, -> do
      where(self.project_type_override.in(CHRONIC_PROJECT_TYPES))
    end
    scope :hud_chronic, -> do
      where(self.project_type_override.in(CHRONIC_PROJECT_TYPES))
    end
    scope :homeless, -> do
      where(self.project_type_override.in(HOMELESS_PROJECT_TYPES))
    end
    scope :hud_homeless, -> do
      where(self.project_type_override.in(CHRONIC_PROJECT_TYPES))
    end
    scope :homeless_sheltered, -> do
      where(self.project_type_override.in(HOMELESS_SHELTERED_PROJECT_TYPES))
    end
    scope :homeless_unsheltered, -> do
      where(self.project_type_override.in(HOMELESS_UNSHELTERED_PROJECT_TYPES))
    end
    scope :residential_non_homeless, -> do
      r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      where(ProjectType: r_non_homeless)
    end
    scope :hud_residential_non_homeless, -> do
      r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      where(self.project_type_override.in(r_non_homeless))
    end

    scope :with_hud_project_type, -> (project_types) do
      where(self.project_type_override.in(project_types))
    end
    scope :with_project_type, -> (project_types) do
      where(project_type_column => project_types)
    end

    scope :in_coc, -> (coc_code:) do
      joins(:project_cocs).
        merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_code))
    end

    scope :night_by_night, -> do
      where(TrackingMethod: 3)
    end

    scope :confidential, -> do
      where(confidential: true)
    end

    scope :coc_funded, -> do
      # hud_continuum_funded overrides ContinuumProject
      where(
        arel_table[:ContinuumProject].eq(1).and(arel_table[:hud_continuum_funded].eq(nil).or(arel_table[:hud_continuum_funded].eq(true))).
        or(arel_table[:hud_continuum_funded].eq(true).and(arel_table[:ContinuumProject].eq(0)))
      )
    end

    # NOTE: Careful, this returns duplicates as it joins inventories.
    # You may want to tack on a distinct, depending on what you need.
    scope :serves_families, -> do
      where(
        id: GrdaWarehouse::Hud::Project.joins(:inventories).
          merge(GrdaWarehouse::Hud::Inventory.serves_families).
          distinct.select(:id)
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
          or(
            p_t[:id].not_in(lit(GrdaWarehouse::Hud::Project.serves_families.select(:id).to_sql))
          )
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

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      else
        qc = -> (s) { connection.quote_column_name s }
        q  = -> (s) { connection.quote s }

        where(
          [
            has_access_to_project_through_viewable_entities(user, q, qc),
            has_access_to_project_through_organization(user, q, qc),
            has_access_to_project_through_data_source(user, q, qc),
            has_access_to_project_through_coc_codes(user, q, qc)
          ].join ' OR '
        )
      end
    end
    scope :editable_by, -> (user) do
      if user&.can_edit_projects?
        viewable_by user
      else
        none
      end
    end

    def self.has_access_to_project_through_viewable_entities(user, q, qc)
      viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table     = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = user.access_groups.pluck(:id)
      group_id_query = if group_ids.empty?
        "0=1"
      else
        "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            WHERE
              #{viewability_table}.#{qc.('entity_id')}   = #{project_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
              AND
              #{project_table}.#{qc.(GrdaWarehouse::Hud::Project.paranoia_column)} IS NULL
        )

      SQL
    end

    def self.has_access_to_project_through_organization(user, q, qc)
      viewability_table   = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table       = quoted_table_name
      organization_table  = GrdaWarehouse::Hud::Organization.quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = user.access_groups.pluck(:id)
      group_id_query = if group_ids.empty?
        "0=1"
      else
        "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            INNER JOIN
            #{organization_table}
            ON
              #{viewability_table}.#{qc.('entity_id')}   = #{organization_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::Hud::Organization.sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
            WHERE
              #{organization_table}.#{qc.('data_source_id')} = #{project_table}.#{qc.('data_source_id')}
              AND
              #{organization_table}.#{qc.('OrganizationID')} = #{project_table}.#{qc.('OrganizationID')}
              AND
              #{organization_table}.#{qc.(GrdaWarehouse::Hud::Organization.paranoia_column)} IS NULL
        )

      SQL
    end

    def self.has_access_to_project_through_data_source(user, q, qc)
      data_source_table = GrdaWarehouse::DataSource.quoted_table_name
      viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table     = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = user.access_groups.pluck(:id)
      group_id_query = if group_ids.empty?
        "0=1"
      else
        "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            INNER JOIN
            #{data_source_table}
            ON
              #{viewability_table}.#{qc.('entity_id')}   = #{data_source_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::DataSource.sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
            WHERE
              #{project_table}.#{qc.('data_source_id')} = #{data_source_table}.#{qc.('id')}
        )

      SQL
    end

    def self.has_access_to_project_through_coc_codes(user, q, qc)
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
              #{project_coc_table}.#{qc[:ProjectID]}      = pt.#{qc[:ProjectID]}
              AND
              #{project_coc_table}.#{qc[:data_source_id]} = pt.#{qc[:data_source_id]}
            WHERE
              (
                (
                  #{project_coc_table}.#{qc[:CoCCode]} IN (#{user.coc_codes.map{ |c| q[c] }.join ',' })
                  AND
                  (
                    #{project_coc_table}.#{qc[:hud_coc_code]} IS NULL
                    OR
                    #{project_coc_table}.#{qc[:hud_coc_code]} = ''
                  )
                )
                OR
                #{project_coc_table}.#{qc[:hud_coc_code]} IN (#{user.coc_codes.map{ |c| q[c] }.join ',' })
              )
              AND
              #{project_table}.#{qc[:id]} = pt.#{qc[:id]}

        )

      SQL
    end

    # make a scope for every project type and a type? method for instances
    RESIDENTIAL_PROJECT_TYPES.each do |k,v|
      scope k, -> { where(self.project_type_column => v) }
      define_method "#{k}?" do
        v.include? self[self.class.project_type_column]
      end
    end

    scope :rrh, -> { where(self.project_type_column => 13) }
    def rrh?
      self[self.class.project_type_column].to_i == 13
    end

    alias_attribute :name, :ProjectName

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
        @psh_types.include?(self.compute_project_type)
    end

    def organization_and_name(include_confidential_names: false)
      if include_confidential_names
        "#{organization&.OrganizationName} / #{self.ProjectName}"
      else
        project_name = self.class.confidentialize(name: self.ProjectName)
        if project_name == self.class.confidential_project_name
          "#{project_name}"
        else
          "#{organization&.OrganizationName} / #{self.ProjectName}"
        end
      end
    end

    def name_and_type(include_confidential_names: false)
      "#{name} (#{HUD.project_type_brief(computed_project_type)})"
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
      @answer ||= GrdaWarehouse::Hud::Project.where(id: id)
        .joins(:services)
        .select(:ProjectID, :data_source_id)
        .where(Services: {RecordType: 12})
        .exists?
      @answer
    end

    # generate a CSV file
    # there may be multiple lines per project
    def self.export_providers(coc_codes)
      spec = {
        hud_org_id:          o_t[:OrganizationID],
        _hud_org_name:       o_t[:OrganizationName],
        provider:            p_t[:ProjectName],
        _provider:           p_t[:ProjectID],
        hud_prog_type:       p_t[project_type_column],
        fed_funding_source:  f_t[:FunderID],
        fed_partner_program: f_t[:FunderID],
        grant_id:            f_t[:GrantID],
        grant_start_date:    f_t[:StartDate],
        grant_end_date:      f_t[:EndDate],
        coc_code:            pc_t[:CoCCode],
        hud_geocode:         g_t[:Geocode],
        current_continuum_project: p_t[:ContinuumProject],
      }
      projects = joins( :funders, :organization, :project_cocs, :geographies ).
        order( arel_table[:ProjectID], pc_t[:CoCCode], f_t[:FunderID] ).
        where( pc_t[:CoCCode].in coc_codes )
      spec.each do |header, selector|
        projects = projects.select selector.as(header.to_s)
      end

      csv = CSV.generate headers: true do |csv|
        headers = spec.keys.reject{ |k| k.to_s.starts_with? '_' }
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

    # when we export, we always need to replace ProjectID with the value of id
    # and OrganizationID with the id of the related organization
    def self.to_csv(scope:, override_project_type:)
      attributes = self.hud_csv_headers.dup
      headers = attributes.clone
      attributes[attributes.index(:ProjectID)] = :id
      attributes[attributes.index(:OrganizationID)] = 'organization.id'

      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map do |attr|
            attr = attr.to_s
            # we need to grab the appropriate id from the related organization
            if attr.include?('.')
              obj, meth = attr.split('.')
              i.send(obj).send(meth)
            else
              if override_project_type && attr == 'ProjectType'
                i.computed_project_type
              elsif attr == 'ResidentialAffiliation'
                i.send(attr).presence || 99
              elsif attr == 'TrackingMethod'
                i.send(attr).presence || 0
              else
                i.send(attr)
              end
            end
          end
        end
      end
    end

    def confidential_hint
      'If marked as confidential, the project name will be replaced with "Confidential Project" within individual client pages. Users with the "Can view confidential enrollment details" will still see the project name.'
    end

    def safe_project_name
      if confidential?
        self.class.confidential_project_name
      else
        self.ProjectName
      end
    end

    # Sometimes all we have is a name, we still want to try and
    # protect those
    def self.confidentialize(name:)
      @confidential_project_names ||= GrdaWarehouse::Hud::Project.where(confidential: true).
        pluck(:ProjectName).
        map(&:downcase).
        map(&:strip)
      if @confidential_project_names.include?(name&.downcase&.strip) || /healthcare/i.match(name).present?
        GrdaWarehouse::Hud::Project.confidential_project_name
      else
        name
      end
    end

    def self.confidential_project_name
      'Confidential Project'
    end

    def self.project_type_column
      if GrdaWarehouse::Config.get(:project_type_override)
        :computed_project_type
      else
        :ProjectType
      end
    end

    def human_readable_project_type
      HUD.project_type(self[self.class.project_type_column])
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
        GrdaWarehouse::Hud::Organization.arel_table[:OrganizationID].eq(arel_table[:OrganizationID])
        .and(GrdaWarehouse::Hud::Organization.arel_table[:data_source_id].eq(arel_table[:data_source_id]))
      ).text_search(text).exists

      where(
        arel_table[:ProjectName].matches(query)
        .or(org_matches)
      )
    end

    def self.options_for_select user:
      # don't cache this, it's a class method
      @options = begin
        options = {}
        self.viewable_by(user).
          joins(:organization).
          order(o_t[:OrganizationName].asc, ProjectName: :asc).
            pluck(o_t[:OrganizationName].as('org_name'), :ProjectName, project_type_column, :id).each do |org, project_name, project_type, id|
            options[org] ||= []
            options[org] << ["#{project_name} (#{HUD::project_type_brief(project_type)})", id]
          end
        options
      end
    end

    def destroy_dependents!
      # Find all PersonalIDs for this project, we'll use these later to clean up clients
      enrollment_ids = enrollments.distinct.pluck(:PersonalID)

      deleted_timestamp = Time.current
      # Inventory related
      project_cocs.update_all(DateDeleted: deleted_timestamp)
      geographies.update_all(DateDeleted: deleted_timestamp)
      inventories.update_all(DateDeleted: deleted_timestamp)
      funders.update_all(DateDeleted: deleted_timestamp)
      affiliations.update_all(DateDeleted: deleted_timestamp)
      residential_affiliations.update_all(DateDeleted: deleted_timestamp)

      # Client enrollment related
      income_benefits.update_all(DateDeleted: deleted_timestamp)
      disabilities.update_all(DateDeleted: deleted_timestamp)
      employment_educations.update_all(DateDeleted: deleted_timestamp)
      health_and_dvs.update_all(DateDeleted: deleted_timestamp)
      services.update_all(DateDeleted: deleted_timestamp)
      exits.update_all(DateDeleted: deleted_timestamp)
      enrollment_cocs.update_all(DateDeleted: deleted_timestamp)
      enrollments.update_all(DateDeleted: deleted_timestamp)

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
      GrdaWarehouse::Hud::Client.where(id: no_enrollments).update_all(DateDeleted: deleted_timestamp) if no_enrollments.present?

      destination_ids = GrdaWarehouse::WarehouseClient.where(source_id: all_clients).pluck(:destination_id)
      # Force reloads of client views
      GrdaWarehouse::Tasks::ServiceHistory::Update.new(client_ids: destination_ids).run!
      destination_ids.each do |id|
        GrdaWarehouse::Hud::Client.clear_view_cache(id)
      end

    end
  end
end
