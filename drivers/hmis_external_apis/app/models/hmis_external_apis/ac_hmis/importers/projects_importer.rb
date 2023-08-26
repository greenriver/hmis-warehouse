###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class ProjectsImporter
    JOB_LOCK_NAME = 'hmis_project_importer'.freeze

    include NotifierConfig

    AbortImportException = Class.new(StandardError)

    attr_accessor :attempt
    attr_accessor :data_source
    attr_accessor :dir
    attr_accessor :extra_columns

    def initialize(dir:, key:, etag:)
      self.attempt = ProjectsImportAttempt.where(etag: etag, key: key).first_or_initialize
      self.data_source = HmisExternalApis::AcHmis.data_source
      self.dir = dir
    end

    def run!
      timeout_seconds = 60
      success = false
      Hmis::HmisBase.with_advisory_lock(JOB_LOCK_NAME, timeout_seconds: timeout_seconds) do
        _run
        success = true
      end
      raise "Could not acquire lock within #{timeout_seconds} seconds" unless success

      success
    end

    protected

    def _run
      start
      sanity_check
      ProjectsImportAttempt.transaction do
        upsert_funders
        upsert_orgs
        upsert_projects
        upsert_walkins
        upsert_inventory
        upsert_project_unit_type_mappings
        Hmis::ProjectUnitTypeMapping.freshen_project_units(user: sys_user)
      end
      analyze
      finish
    rescue AbortImportException => e
      @notifier.ping('Failure in project importer', { exception: e })
      Rails.logger.fatal e.message
      Rails.logger.fatal 'ProjectsImporter aborted before it finished.'
    end

    def start
      setup_notifier('HMIS Projects')
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.current
      attempt.status = ProjectsImportAttempt::STARTED
      attempt.save!
    end

    def sanity_check
      msg = []

      msg << 'Funder.csv was not present.' unless File.exist?("#{dir}/Funder.csv")
      msg << 'Organization.csv was not present.' unless File.exist?("#{dir}/Organization.csv")
      msg << 'Project.csv was not present.' unless File.exist?("#{dir}/Project.csv")
      msg << 'Inventory.csv was not present.' unless File.exist?("#{dir}/Inventory.csv")

      return unless msg.present?

      msg = msg.join('. ')

      Rails.logger.error(msg)
      attempt.attempted_at = Time.now
      attempt.status = ProjectsImportAttempt::FAILED
      attempt.result = { error: msg }
      attempt.save!
      raise AbortImportException, msg
    end

    def upsert_funders
      file = 'Funder.csv'

      check_columns(
        file: file,
        expected_columns: ['FunderID', 'ProjectID', 'Funder', 'OtherFunder', 'GrantID', 'StartDate', 'EndDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
        critical_columns: ['FunderID'],
      )

      generic_upsert(
        file: 'Funder.csv',
        conflict_target: ['"FunderID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Funder,
      )
    end

    def upsert_orgs
      file = 'Organization.csv'

      check_columns(
        file: file,
        expected_columns: ['OrganizationID', 'OrganizationName', 'VictimServiceProvider', 'OrganizationCommonName', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
        critical_columns: ['OrganizationID'],
      )

      generic_upsert(
        file: file,
        conflict_target: ['"OrganizationID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Organization,
      )
    end

    def upsert_projects
      file = 'Project.csv'

      check_columns(
        file: file,
        expected_columns: ['ProjectID', 'OrganizationID', 'ProjectName', 'ProjectCommonName', 'OperatingStartDate', 'OperatingEndDate', 'ContinuumProject', 'ProjectType', 'HousingType', 'ResidentialAffiliation', 'TrackingMethod', 'HMISParticipatingProject', 'TargetPopulation', 'HOPWAMedAssistedLivingFac', 'PITCount', 'Walkin', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
        critical_columns: ['ProjectID'],
      )

      @project_result = generic_upsert(
        file: file,
        conflict_target: ['"ProjectID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Project,
        ignore_columns: ['Walkin'],
      )
    end

    def upsert_walkins
      Rails.logger.info 'Upserting walkins'
      project_ids = @project_result.ids
      walkin = records_from_csv('Project.csv').map { |x| x['Walkin'] }

      project_ids.length != walkin.length and raise(AbortImportException, 'Project upsert should have been the same length as the parsed csv')

      project_ids.zip(walkin).each do |(project_id, bool_str)|
        next unless bool_str.present?

        cde = Hmis::Hud::CustomDataElement
          .where(
            owner_type: 'Hmis::Hud::Project',
            owner_id: project_id,
            data_element_definition: cded,
            data_source: data_source,
          )
          .first_or_initialize

        cde.update!(
          user: sys_user,
          value_boolean:
            case bool_str
            when '1' then true
            when '0' then false
            end,
        )
      end
    end

    def upsert_inventory
      file = 'Inventory.csv'

      check_columns(
        file: file,
        expected_columns: ['InventoryID', 'ProjectID', 'CoCCode', 'HouseholdType', 'Availability', 'UnitInventory', 'BedInventory', 'CHVetBedInventory', 'YouthVetBedInventory', 'VetBedInventory', 'CHYouthBedInventory', 'YouthBedInventory', 'CHBedInventory', 'OtherBedInventory', 'ESBedType', 'InventoryStartDate', 'InventoryEndDate', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'],
        critical_columns: ['InventoryID'],
      )

      @project_result = generic_upsert(
        file: file,
        conflict_target: ['"InventoryID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Inventory,
      )
    end

    def upsert_project_unit_type_mappings
      file = 'ProjectUnitTypes.csv'

      columns = ['ProgramID', 'UnitTypeID', 'UnitCapacity', 'IsActive']
      check_columns(file: file, expected_columns: columns, critical_columns: columns)

      projects_ids_by_hud = Hmis::Hud::Project
        .where(data_source: data_source)
        .pluck(:ProjectID, :id)
        .to_h
      unit_type_ids_by_mper = Hmis::UnitType
        .joins(:mper_id)
        .pluck(HmisExternalApis::ExternalId.arel_table[:value], :id)
        .to_h

      csv = records_from_csv(file)
      records = csv.each.map do |row|
        active = case row.fetch('IsActive')
        when 'Y'
          true
        when 'N'
          false
        else
          raise 'unknown value for IsActive'
        end

        db_project_id = projects_ids_by_hud.fetch(row['ProgramID'], nil)
        if db_project_id.nil?
          Rails.logger.info "Skipping unrecognized ProgramID: #{row['ProgramID']}"
          next
        end

        db_unit_type_id = unit_type_ids_by_mper.fetch(row['UnitTypeID'], nil)
        raise "UnitTypeMapping error: UnitTypeID not found: #{row['UnitTypeID']}" unless db_unit_type_id.present?

        {
          project_id: db_project_id,
          unit_type_id: db_unit_type_id,
          unit_capacity: row.fetch('UnitCapacity'),
          active: active,
        }
      end.compact

      Hmis::ProjectUnitTypeMapping.import!(
        records,
        validate: false,
        batch_size: 1_000,
        on_duplicate_key_update: {
          conflict_target: [:project_id, :unit_type_id],
          columns: [:unit_capacity, :active],
        },
      )
    end

    def analyze
      Rails.logger.info 'Analyzing imported tables'
      ProjectsImportAttempt.connection.exec_query('ANALYZE "Funder", "Project", "Organization", "CustomDataElements";')
    end

    def finish
      attempt.status = ProjectsImportAttempt::SUCCEEDED
      attempt.save!
    end

    def check_columns(file:, expected_columns:, critical_columns:)
      rows = records_from_csv(file, row_limit: 1)

      raise AbortImportException, "There was no data in #{file}." if rows.empty?

      keys = rows.first.to_h.keys

      missing_columns = expected_columns - keys
      missing_critical_columns = critical_columns - keys

      self.extra_columns = keys - expected_columns

      Rails.logger.warn("Skipping extra columns (#{extra_columns.join(', ')}) in #{file}") if extra_columns.present?

      raise(AbortImportException, "There were critical missing columns in #{file}: #{missing_critical_columns.join(', ')}.") if missing_critical_columns.present?

      Rails.logger.warn("There were non-critical missing columns in #{file}: #{missing_columns.join(', ')}.") if missing_columns.present?
    end

    def records_from_csv(file, row_limit: nil)
      io = File.open(file, 'r')

      # Checking for BOM
      if io.read(3).bytes == [239, 187, 191]
        Rails.logger.info 'Byte-order marker (BOM) found. Skipping it.'
      else
        io.rewind
      end

      if row_limit
        CSV.parse(io.read, **csv_config).take(row_limit)
      else
        CSV.parse(io.read, **csv_config)
      end
    end

    def csv_config
      {
        headers: true,
        skip_lines: /\A\s*\z/,
      }
    end

    def generic_upsert(file:, conflict_target:, klass:, ignore_columns: [])
      Rails.logger.info "Upserting #{file}"

      csv = records_from_csv(file)

      columns_to_update = csv.headers - conflict_target - ignore_columns

      records = csv.each.map(&:to_h)

      records.each do |r|
        r['data_source_id'] = data_source.id
      end

      if ignore_columns.present?
        records.each do |r|
          ignore_columns.each do |col|
            r.delete(col)
          end
        end
      end

      if extra_columns.present?
        records.each do |r|
          extra_columns.each do |col|
            r.delete(col)
          end
        end
      end

      result = klass.import(
        records,
        validate: false,
        batch_size: 1_000,
        on_duplicate_key_update: {
          conflict_target: conflict_target,
          columns: columns_to_update,
        },
      )

      if result.failed_instances.present?
        msg = "Failed: #{result.failed_instances}. Aborting"
        raise AbortImportException, msg
      end

      attempt.update_attribute(:status, "finished #{file}")

      Rails.logger.info "Upserted #{result.ids.length} records"

      result
    ensure
      self.extra_columns = []
    end

    def cded
      return @cded if @cded.present?

      @cded = Hmis::Hud::CustomDataElementDefinition.where(owner_type: 'Hmis::Hud::Project', key: 'direct_entry', data_source_id: data_source.id).first_or_initialize

      return @cded unless @cded.new_record?

      @cded.update!(
        field_type: 'boolean',
        key: 'direct_entry',
        label: 'Direct Entry',
        repeats: false,
        user: sys_user,
      )

      @cded
    end

    def sys_user
      @sys_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end
  end
end
