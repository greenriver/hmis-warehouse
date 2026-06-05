###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Creates or updates the HMIS records that provide the structural scaffolding
  # a simulation needs: organizations, projects, ProjectCoc, Inventory, and
  # Funder records. All operations are idempotent — running twice produces the
  # same set of records.
  #
  # Usage:
  #   config = HmisSimulation::ConfigLoader.from_app_config('hmis_simulation/demo-coc')
  #   HmisSimulation::Bootstrapper.new(config).run!
  class Bootstrapper
    EXPORT_ID = 'HMIS_SIMULATION'
    GEOCODE   = '000000'
    OPERATING_START_DATE = Date.new(2020, 1, 1)

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

      Hmis::Hud::Base.transaction do
        @config['organizations'].each do |org_cfg|
          org = find_or_create_organization(org_cfg, data_source: data_source, user_id: user_id)

          org_cfg['projects'].each do |proj_cfg|
            project = find_or_create_project(proj_cfg, org: org, data_source: data_source, user_id: user_id)
            find_or_create_project_coc(project, coc_code: primary_coc, data_source: data_source, user_id: user_id)

            find_or_create_inventory(project, proj_cfg, coc_code: primary_coc, data_source: data_source, user_id: user_id) unless NON_RESIDENTIAL_PROJECT_TYPES.include?(project.ProjectType)

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
        )
        coc.save!
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
        inv.assign_attributes(
          **hud_attrs(data_source: data_source, user_id: user_id),
          InventoryID: FakeIdentifier.uuid,
          ProjectID: project.ProjectID,
          CoCCode: coc_code,
          HouseholdType: 1,
          BedInventory: capacity,
          UnitInventory: capacity,
          InventoryStartDate: OPERATING_START_DATE,
        )
        inv.save!
      end
    end

    def find_or_create_funder(funder_cfg, project:, data_source:, user_id:)
      funder_code = funder_cfg['funder'].to_i
      grant_id    = funder_cfg['grant_id'].to_s

      Hmis::Hud::Funder.find_or_initialize_by(
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
        Funder: funder_code,
      ).tap do |funder|
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
  end
end
