###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  # Leaving commented-out in case we need to do something similar for 2024=>2026
  #
  # class CsvTransformer2022to2024 < HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer
  #   def self.destination_headers(target_class)
  #     case [target_class]
  #     when [GrdaWarehouse::Hud::Project]
  #       super(target_class) + ['Walkin']
  #     else
  #       super(target_class)
  #     end
  #   end
  # end

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
        _run(dir)
        success = true
      end
      raise "Could not acquire lock within #{timeout_seconds} seconds" unless success

      success
    end

    protected

    def run_in_dir(new_dir)
      original_dir = dir
      ret = nil
      Dir.chdir(dir) do
        self.dir = new_dir
        ret = yield
      end
      self.dir = original_dir
      ret
    end

    def _run(hud_dir)
      start
      sanity_check
      ProjectsImportAttempt.transaction do
        run_in_dir(hud_dir) do
          upsert_hud_file(file: 'Organization.csv', klass: GrdaWarehouse::Hud::Organization)
          upsert_projects
          upsert_walkins # import flag indicating which projects accept walk-ins
          upsert_hud_file(file: 'Funder.csv', klass: GrdaWarehouse::Hud::Funder)
          upsert_hud_file(file: 'Inventory.csv', klass: GrdaWarehouse::Hud::Inventory)
          upsert_hud_file(file: 'ProjectCoC.csv', klass: GrdaWarehouse::Hud::ProjectCoc)
          upsert_hud_file(file: 'HMISParticipation.csv', klass: GrdaWarehouse::Hud::HmisParticipation)
          upsert_hud_file(file: 'CEParticipation.csv', klass: GrdaWarehouse::Hud::CeParticipation)
        end
        run_in_dir(dir) do
          upsert_project_unit_type_mappings
        end
        Hmis::ProjectUnitTypeMapping.freshen_project_units(user: sys_user)
        cleanup_project_dates
        cleanup_dangling_funders
      end
      analyze
      finish
    rescue AbortImportException => e
      @notifier.ping('Failure in project importer', { exception: e })
      Rails.logger.fatal e.message
      Rails.logger.fatal 'ProjectsImporter aborted before it finished.'
      raise e if Rails.env.test?
    end

    def start
      setup_notifier('HMIS MPER Project Importer')
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.current
      attempt.status = ProjectsImportAttempt::STARTED
      attempt.save!
    end

    def sanity_check
      msg = []

      [
        'Funder.csv',
        'Organization.csv',
        'Project.csv',
        'Inventory.csv',
        'ProjectCoC.csv',
        'HMISParticipation.csv',
        'CEParticipation.csv',
        'ProjectUnitTypes.csv',
      ].each do |file|
        msg << "#{file} was not present." unless File.exist?("#{dir}/#{file}")
      end

      return unless msg.present?

      msg = msg.join('. ')

      Rails.logger.error(msg)
      attempt.attempted_at = Time.now
      attempt.status = ProjectsImportAttempt::FAILED
      attempt.result = { error: msg }
      attempt.save!
      raise AbortImportException, msg
    end

    def upsert_hud_file(file:, klass:)
      hud_key = klass.hud_key&.to_s
      raise 'hud_key not found' unless hud_key

      check_columns(
        file: file,
        expected_columns: klass.hmis_configuration(version: '2024').keys.map(&:to_s),
        critical_columns: [hud_key],
      )

      generic_upsert(
        file: file,
        conflict_target: ["\"#{hud_key}\"", 'data_source_id'],
        klass: klass,
      )
    end

    # Doesn't match HUD spec exactly, has additional column 'Walkin'
    def upsert_projects
      file = 'Project.csv'

      hud_columns = GrdaWarehouse::Hud::Project.hmis_configuration(version: '2024').keys.map(&:to_s)
      check_columns(
        file: file,
        expected_columns: hud_columns + ['Walkin'],
        critical_columns: ['ProjectID'],
      )

      generic_upsert(
        file: file,
        conflict_target: ['"ProjectID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Project,
        ignore_columns: ['Walkin'],
      )
    end

    def upsert_walkins
      Rails.logger.info 'Upserting walkins'
      project_id_to_pk = Hmis::Hud::Project.hmis.pluck(:ProjectID, :id).to_h

      records_from_csv('Project.csv').each do |row|
        bool_str = row['Walkin']
        next unless bool_str.present?

        project_id = project_id_to_pk[row['ProjectID']]
        raise "ProjectID #{row['ProjectID']} not found" unless project_id

        cde = Hmis::Hud::CustomDataElement.
          where(
            owner_type: 'Hmis::Hud::Project',
            owner_id: project_id,
            data_element_definition: cded,
            data_source: data_source,
          ).
          first_or_initialize

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

    def upsert_project_unit_type_mappings
      file = 'ProjectUnitTypes.csv'

      columns = ['ProgramID', 'UnitTypeID', 'UnitCapacity', 'IsActive']
      check_columns(file: file, expected_columns: columns, critical_columns: columns)

      projects_ids_by_hud = Hmis::Hud::Project.
        where(data_source: data_source).
        pluck(:ProjectID, :id).
        to_h
      unit_type_ids_by_mper = Hmis::UnitType.
        joins(:mper_id).
        pluck(HmisExternalApis::ExternalId.arel_table[:value], :id).
        to_h

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

      @notifier.ping "Upserted #{records.size} records from #{file}"
    end

    # Replace "9999" end date with nil
    def cleanup_project_dates
      ids_to_update = Hmis::Hud::Project.where(data_source: data_source).
        open_on_date.
        filter { |p| p.operating_end_date&.year == 9999 }.
        map(&:id)

      Hmis::Hud::Project.where(id: ids_to_update).update_all(operating_end_date: nil)
    end

    def cleanup_dangling_funders
      # The Funder.csv file contains funders for Projects we don't have. Delete them.
      valid_project_ids = Hmis::Hud::Project.where(data_source: data_source).pluck(:project_id)
      dangling_funders = Hmis::Hud::Funder.where(data_source: data_source).where.not(project_id: valid_project_ids)

      @notifier.ping "Soft-deleting #{dangling_funders.size} dangling Funder records" if dangling_funders.any?
      dangling_funders.each(&:destroy!)
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
      io = File.open(File.join(dir, file), 'r')

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

      # Fix known issues in CSV headers
      header_fixes = {
        'HousingAssessmemnt' => 'HousingAssessment',
        'ZIP' => 'Zip',
      }
      csv_headers = csv.headers.map { |val| header_fixes[val] || val }
      columns_to_update = csv_headers - conflict_target - ignore_columns

      records = csv.each.map(&:to_h)

      records.each do |r|
        r['data_source_id'] = data_source.id

        # Fix issues with hash keys (ZIP=>Zip)
        header_fixes.each do |file_col, db_col|
          r[db_col] = r.delete file_col if r[file_col]
        end
      end

      # Validate format of all dates before attempting import, so we don't import them incorrectly
      date_columns = csv_headers.filter { |h| h.end_with?('Date') }
      if date_columns.any?
        date_columns.each do |col|
          records.each do |r|
            next unless r[col]
            # break as soon as we find 1 correctly formatted record for this column
            break if valid_date?(r[col])

            # Abort import if we find a malformatted date. Dates like '30-JUN-24' would be incorrectly
            # parsed and lead to unexpected behavior in the HMIS.
            raise(AbortImportException, "Incorrectly formatted date in #{file} #{col}: #{r[col]}")
          end
        end
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

      # Drop records with duplicate conflict targets (HUD keys)
      unique_records = records.index_by do |record|
        conflict_target.map { |col| record[col.gsub(/\"/, '')] }.join(':')
      end.values.flatten

      result = klass.import(
        unique_records,
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

      @notifier.ping "Upserted #{result.ids.length} records from #{file}"
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

    # Leaving commented-out in case we need to do something similar for 2024=>2026
    #
    # def infer_hud_version_from_project_cols
    #   headers = run_in_dir(dir) do
    #     records_from_csv('Project.csv', row_limit: 1).first.to_h.keys.to_set
    #   end
    #   if headers.include?('RRHSubType')
    #     '2024'
    #   elsif headers.include?('ResidentialAffiliation') || headers.include?('TrackingMethod')
    #     '2022'
    #   end
    # end

    # Validate date format 'YYYY-MM-DD'
    def valid_date?(str)
      format_ok = str.match(/\d{4}-\d{2}-\d{2}/)
      return false unless format_ok

      begin
        Date.strptime(str, '%Y-%m-%d')
      rescue StandardError
        return false
      end

      true
    end
  end
end
