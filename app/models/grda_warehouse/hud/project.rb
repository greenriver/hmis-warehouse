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

    belongs_to :organization, class_name: 'GrdaWarehouse::Hud::Organization', primary_key: ['OrganizationID', :data_source_id], foreign_key: ['OrganizationID', :data_source_id], inverse_of: :projects
    belongs_to :data_source, inverse_of: :projects
    belongs_to :export, **hud_belongs(Export), inverse_of: :projects
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

    scope :residential, -> { where ProjectType: RESIDENTIAL_PROJECT_TYPE_IDS }

    scope :coc_funded, -> do
      # hud_continuum_funded overrides ContinuumProject
      where(
        arel_table[:ContinuumProject].eq(1).and(arel_table[:hud_continuum_funded].eq(nil)).
        or(arel_table[:hud_continuum_funded].eq(true))
      )
    end

    # make a scope for every project type and a type? method for instances
    RESIDENTIAL_PROJECT_TYPES.each do |k,v|
      scope k, -> { where ProjectType: v }
      define_method "#{k}?" do
        v.include? self.ProjectType
      end
    end

    def name
      self.ProjectName
    end

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
      @confidential_project_names ||= self.where(confidential: true).pluck(:ProjectName)
      if @confidential_project_names.include?(name)
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