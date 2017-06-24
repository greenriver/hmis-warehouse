# these are also sometimes called programs
module GrdaWarehouse::Hud
  class Project < Base
    include ArelHelper
    self.table_name = :Project
    self.hud_key = :ProjectID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "ProjectID",
        "OrganizationID",
        "ProjectName",
        "ProjectCommonName",
        "ContinuumProject",
        "ProjectType",
        "ResidentialAffiliation",
        "TrackingMethod",
        "TargetPopulation",
        "PITCount",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
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
    HOMELESS_PROJECT_TYPES = RESIDENTIAL_PROJECT_TYPES.values_at(:es, :so, :sh, :th).flatten
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

    belongs_to :organization, class_name: 'GrdaWarehouse::Hud::Organization', primary_key: ['OrganizationID', :data_source_id], foreign_key: ['OrganizationID', :data_source_id], inverse_of: :projects
    belongs_to :data_source, inverse_of: :projects
    belongs_to :export, **hud_belongs(Export), inverse_of: :projects

    has_and_belongs_to_many :project_groups, 
      class_name: GrdaWarehouse::ProjectGroup.name,
      join_table: :project_project_groups

    has_many :service_history, class_name: 'GrdaWarehouse::ServiceHistory', primary_key: [:data_source_id, :ProjectID, :OrganizationID], foreign_key: [:data_source_id, :project_id, :organization_id]
    has_many :project_cocs, **hud_many(ProjectCoc), inverse_of: :project
    has_many :sites, through: :project_cocs, source: :sites
    has_many :enrollments, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: ['ProjectID', :data_source_id], foreign_key: ['ProjectID', :data_source_id], inverse_of: :project
    has_many :income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', primary_key: ['ProjectID', :data_source_id], foreign_key: ['ProjectID', :data_source_id], inverse_of: :project
    has_many :services, through: :enrollments, source: :services
    has_many :inventories, through: :project_cocs, source: :inventories
    has_many :clients, through: :enrollments, source: :clients
    has_many :funders, class_name: 'GrdaWarehouse::Hud::Funder', primary_key: ['ProjectID', :data_source_id], foreign_key: ['ProjectID', :data_source_id], inverse_of: :projects
    has_many :affiliations, **hud_many(Affiliation), inverse_of: :project
    has_many :enrollment_cocs, **hud_many(EnrollmentCoc), inverse_of: :project
    has_many :funders, **hud_many(Funder), inverse_of: :project
    has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::Hud::UserViewableEntity'

    # Warehouse Reporting
    has_many :data_quality_reports, class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.name
    has_one :current_data_quality_report, -> do
      where(processing_errors: nil).where.not(completed_at: nil).order(created_at: :desc).limit(1)
    end, class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.name
    has_many :contacts, class_name: GrdaWarehouse::Contact::Project.name, foreign_key: :entity_id
    has_many :organization_contacts, through: :organization, source: :contacts

    scope :residential, -> { where ProjectType: RESIDENTIAL_PROJECT_TYPE_IDS }

    scope :coc_funded, -> do
      # hud_continuum_funded overrides ContinuumProject
      where(
        arel_table[:ContinuumProject].eq(1).and(arel_table[:hud_continuum_funded].eq(nil)).
        or(arel_table[:hud_continuum_funded].eq(true))
      )
    end
    scope :viewable_by, -> (user) do
      if user.roles.where( can_view_everything: true ).exists?
        current_scope
      else
        # unfortunately an arel bug prevented our using a much simpler query using existence subqueries
        ds_at = Arel::Table.new GrdaWarehouse::DataSource.table_name
        v_at  = Arel::Table.new GrdaWarehouse::Hud::UserViewableEntity.table_name
        v_at2 = Arel::Table.new v_at.table_name
        v_at3 = Arel::Table.new v_at.table_name
        p_at  = arel_table
        o_at  = Arel::Table.new GrdaWarehouse::Hud::Organization.table_name
        ij_t = Arel::Table.new 'ijp_t'
        # add some aliases to make this more composable
        pfx = "p_vb_"
        ds_at.table_alias  = "#{pfx}_ds_at"
        v_at.table_alias   = "#{pfx}_v_at"
        v_at2.table_alias  = "#{pfx}_v_at2"
        v_at3.table_alias  = "#{pfx}_v_at3"
        o_at.table_alias   = "#{pfx}_o_at"
        ds_to_v = ds_at.join( v_at, Arel::Nodes::OuterJoin ).
          on(
              v_at[:entity_type].eq(GrdaWarehouse::DataSource.sti_name).
            and(
              v_at[:entity_id].  eq p_at[:data_source_id]
            ).
            and(
              v_at[:user_id].    eq user.id
            )
          ).
          join_sources
        o_to_v = o_at.join( 
            v_at2.join(o_at).
              project( o_at[:data_source_id], o_at[:OrganizationID] ).
              on(
                  v_at2[:entity_type].eq(GrdaWarehouse::Hud::Organization.sti_name).
                and(
                  v_at2[:user_id].    eq user.id
                ).
                and(
                  v_at2[:entity_id].  eq o_at[:id]
                ).
                and(
                  o_at[:DateDeleted]. not_eq nil
                )
              ).
              as(ij_t.table_name),
            Arel::Nodes::OuterJoin
          ).
          on(
              ij_t[:data_source_id].eq(p_at[:data_source_id]).
            and(
              ij_t[:OrganizationID].eq p_at[:OrganizationID]
            )
          ).
          join_sources
        p_to_v = p_at.join( 
            v_at3,
            Arel::Nodes::OuterJoin
          ).
          on(
              v_at3[:entity_type].eq(sti_name).
            and(
              v_at3[:entity_id].  eq p_at[:id]
            ).
            and(
              v_at3[:user_id].    eq user.id
            )
          ).
          join_sources
        joins(ds_to_v).
        joins(o_to_v).
        joins(p_to_v).
          where.not(
              v_at[:id].             eq(nil).
            and(
              ij_t[:data_source_id].eq nil
            ).
            and(
              v_at3[:id].            eq nil
            )
          )
      end
    end

    # make a scope for every project type and a type? method for instances
    RESIDENTIAL_PROJECT_TYPES.each do |k,v|
      scope k, -> { where ProjectType: v }
      define_method "#{k}?" do
        v.include? self.ProjectType
      end
    end

    alias_attribute :name, :ProjectName

    def organization_and_name(include_confidential_names: false)
      "#{organization.name} / #{name}"
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

    # when we export, we always need to replace ProjectID with the value of id
    # and OrganizationID with the id of the related organization
    def self.to_csv(scope:, override_project_type:)
      attributes = self.hud_csv_headers
      headers = attributes.clone
      attributes[attributes.index('ProjectID')] = 'id'
      attributes[attributes.index('OrganizationID')] = 'organization.id'

      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map do |attr|
            # we need to grab the appropriate id from the related organization
            if attr.include?('.')
              obj, meth = attr.split('.')
              i.send(obj).send(meth)
            else
              if override_project_type && attr == 'ProjectType'
                i.act_as_project_type.presence || i.send(attr)
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

    # Not currently used, but represents the appropriate pattern
    # for HUD reporting project type
    def self.act_as_project_overlay
      at = self.class.arel_table
      nf( 'COALESCE', [ at[:act_as_project_type], at[:ProjectType] ] ).as('ProjectType').to_sql
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
      @confidential_project_names ||= GrdaWarehouse::Hud::Project.where(confidential: true).pluck(:ProjectName).map(&:downcase).map(&:strip)
      if @confidential_project_names.include?(name.downcase.strip)
        GrdaWarehouse::Hud::Project.confidential_project_name
      else
        name
      end
    end

    def self.confidential_project_name
      'Confidential Project'
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
  end
end