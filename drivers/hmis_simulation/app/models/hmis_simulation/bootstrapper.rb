###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Creates or updates the HMIS records that provide the structural scaffolding
  # a simulation needs: organizations, projects, ProjectCoc, Inventory, Funder,
  # HmisParticipation, and CeParticipation records. All operations are idempotent
  # — running twice produces the same set of records.
  #
  # Usage:
  #   config = HmisSimulation::ConfigLoader.from_app_config('hmis_simulation/demo-coc')
  #   HmisSimulation::Bootstrapper.new(config).run!
  class Bootstrapper
    EXPORT_ID = 'HMIS_SIMULATION'
    GEOCODE   = '000000'
    OPERATING_START_DATE = Date.new(2020, 1, 1)
    PROJECT_COC_ZIP = '99901'
    PROJECT_COC_GEOGRAPHY_TYPE = 1 # Urban

    # Project types that do not require Inventory records (SO, SSO, Other,
    # Day Shelter, HP, CE — matches HudUtility2026#project_types_without_inventory)
    NON_RESIDENTIAL_PROJECT_TYPES = [4, 6, 7, 11, 12, 14].freeze

    def initialize(config)
      @config = config.deep_stringify_keys
    end

    def run!
      validate!

      data_source = GrdaWarehouse::DataSource.find(@config['data_source_id'])
      user_id     = Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
      primary_coc = @config.dig('coc_codes', 'primary')

      find_or_create_export(data_source: data_source)

      Hmis::Hud::Base.transaction do
        @config['organizations'].each do |org_cfg|
          org = find_or_create_organization(org_cfg, data_source: data_source, user_id: user_id)

          org_cfg['projects'].each do |proj_cfg|
            project = find_or_create_project(proj_cfg, org: org, data_source: data_source, user_id: user_id)
            find_or_create_project_coc(project, coc_code: primary_coc, data_source: data_source, user_id: user_id)
            find_or_create_hmis_participation(project, proj_cfg, data_source: data_source, user_id: user_id)

            find_or_create_inventory(project, proj_cfg, coc_code: primary_coc, data_source: data_source, user_id: user_id) unless NON_RESIDENTIAL_PROJECT_TYPES.include?(project.ProjectType)

            find_or_create_ce_participation(project, proj_cfg, data_source: data_source, user_id: user_id) if project.ProjectType == 14

            (proj_cfg['funders'] || []).each do |funder_cfg|
              find_or_create_funder(funder_cfg, project: project, data_source: data_source, user_id: user_id)
            end
          end
        end
      end
    end

    private

    def validate!
      validator = ConfigValidator.new(@config)
      return if validator.valid?

      raise ConfigError, "Simulation config is invalid:\n#{validator.errors.join("\n")}"
    end

    def hud_attrs(data_source:, user_id:)
      {
        data_source_id: data_source.id,
        UserID: user_id,
        ExportID: EXPORT_ID,
        DateCreated: Time.current,
        DateUpdated: Time.current,
      }
    end

    # For data to show up on the Data Sources page it needs an export record OR to be marked as an HMIS data source.
    # For now, we'll just create an export record.
    def find_or_create_export(data_source:)
      Hmis::Hud::Export.find_or_initialize_by(
        data_source_id: data_source.id,
        ExportID: EXPORT_ID,
      ).tap do |export|
        next unless export.new_record?

        export.assign_attributes(
          ExportDate: Time.current,
          ExportStartDate: OPERATING_START_DATE,
          ExportEndDate: Date.current,
          SoftwareName: 'HmisSimulation',
          SoftwareVersion: '1.0',
          ExportPeriodType: 3,
          ExportDirective: 2,
          HashStatus: 1,
        )
        export.save!
      end
    end

    def find_or_create_organization(org_cfg, data_source:, user_id:)
      Hmis::Hud::Organization.find_or_initialize_by(
        data_source_id: data_source.id,
        OrganizationName: org_cfg['name'],
      ).tap do |org|
        next unless org.new_record?

        org.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          OrganizationID: FakeIdentifier.uuid,
          VictimServiceProvider: false,
        )
        org.save!
      end
    end

    def find_or_create_project(proj_cfg, org:, data_source:, user_id:)
      Hmis::Hud::Project.find_or_initialize_by(
        data_source_id: data_source.id,
        ProjectName: proj_cfg['name'],
      ).tap do |project|
        next unless project.new_record?

        project.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          ProjectID: FakeIdentifier.uuid,
          OrganizationID: org.OrganizationID,
          organization: org,
          ProjectType: proj_cfg['project_type'],
          OperatingStartDate: OPERATING_START_DATE,
          ContinuumProject: 0,
          HMISParticipatingProject: 1,
        )
        project.save!
      end
    end

    def find_or_create_project_coc(project, coc_code:, data_source:, user_id:)
      Hmis::Hud::ProjectCoc.find_or_initialize_by(
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
        CoCCode: coc_code,
      ).tap do |coc|
        next unless coc.new_record?

        coc.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          ProjectCoCID: FakeIdentifier.uuid,
          ProjectID: project.ProjectID,
          Geocode: GEOCODE,
          Zip: PROJECT_COC_ZIP,
          GeographyType: PROJECT_COC_GEOGRAPHY_TYPE,
        )
        coc.save!
      end
    end

    def find_or_create_hmis_participation(project, proj_cfg, data_source:, user_id:)
      Hmis::Hud::HmisParticipation.find_or_initialize_by(
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
      ).tap do |participation|
        next unless participation.new_record?

        participation.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          HMISParticipationID: FakeIdentifier.uuid,
          ProjectID: project.ProjectID,
          HMISParticipationType: proj_cfg.fetch('hmis_participation_type', 1).to_i,
          HMISParticipationStatusStartDate: OPERATING_START_DATE,
        )
        participation.save!
      end
    end

    def find_or_create_ce_participation(project, proj_cfg, data_source:, user_id:)
      Hmis::Hud::CeParticipation.find_or_initialize_by(
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
      ).tap do |participation|
        next unless participation.new_record?

        ce_cfg = proj_cfg.fetch('ce_participation', {})
        participation.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          CEParticipationID: FakeIdentifier.uuid,
          ProjectID: project.ProjectID,
          AccessPoint: ce_cfg.fetch('access_point', 0).to_i,
          PreventionAssessment: ce_cfg.fetch('prevention_assessment', 0).to_i,
          CrisisAssessment: ce_cfg.fetch('crisis_assessment', 1).to_i,
          HousingAssessment: ce_cfg.fetch('housing_assessment', 1).to_i,
          DirectServices: ce_cfg.fetch('direct_services', 1).to_i,
          ReceivesReferrals: ce_cfg.fetch('receives_referrals', 1).to_i,
          CEParticipationStatusStartDate: OPERATING_START_DATE,
        )
        participation.save!
      end
    end

    def find_or_create_inventory(project, proj_cfg, coc_code:, data_source:, user_id:)
      Hmis::Hud::Inventory.find_or_initialize_by(
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
        CoCCode: coc_code,
      ).tap do |inv|
        next unless inv.new_record?

        capacity = proj_cfg['capacity'].to_i.then { |c| c.positive? ? c : 10 }
        rules    = ComplianceRules.rules_for(project.ProjectType)&.dig('bootstrap') || {}
        bed_seed = @config['seed'].to_i + HmisSimulation::Hashing.stable_hash(project.ProjectID.to_s)
        vet, youth, ch = sub_bed_partition(capacity, seed: bed_seed) if rules['track_vet_beds']

        inv.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          InventoryID: FakeIdentifier.uuid,
          ProjectID: project.ProjectID,
          CoCCode: coc_code,
          HouseholdType: 1,
          BedInventory: capacity,
          UnitInventory: capacity,
          HMISParticipatingBeds: capacity,
          InventoryStartDate: OPERATING_START_DATE,
          ESBedType: (rules['es_bed_type'] ? 1 : nil),
          VetBedInventory: vet || 0,
          YouthBedInventory: youth || 0,
          CHBedInventory: ch || 0,
        )
        inv.save!
      end
    end

    def find_or_create_funder(funder_cfg, project:, data_source:, user_id:)
      funder_code = funder_cfg['funder'].to_i
      grant_id    = funder_cfg['grant_id'].to_s

      # The Funder column is stored as varchar but the model attribute is declared
      # as :integer, so ActiveRecord binds an integer parameter and PostgreSQL
      # rejects the varchar = integer comparison. Cast the column explicitly.
      Hmis::Hud::Funder.where(
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
      ).where('"Funder"::integer = ?', funder_code).first_or_initialize.tap do |funder|
        next unless funder.new_record?

        funder.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          FunderID: FakeIdentifier.uuid,
          ProjectID: project.ProjectID,
          Funder: funder_code,
          GrantID: grant_id,
          StartDate: OPERATING_START_DATE,
        )
        funder.save!
      end
    end

    # Randomly partition +total+ into three non-negative integers [vet, youth, ch]
    # that sum exactly to +total+, using two random split points.
    # Accepts an optional +seed+ for deterministic output across process restarts.
    def sub_bed_partition(total, seed: nil)
      return [0, 0, 0] if total.zero?

      rng = seed ? Random.new(seed) : Random.new
      splits = 2.times.map { rng.rand(total + 1) }.sort
      [splits[0], splits[1] - splits[0], total - splits[1]]
    end
  end
end
