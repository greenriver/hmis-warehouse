###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class ProjectsImporter
    include NotifierConfig

    AbortImportException = Class.new(StandardError)

    attr_accessor :attempt
    attr_accessor :data_source
    attr_accessor :dir

    def initialize(dir:, key:, etag:)
      self.attempt = ProjectsImportAttempt.where(etag: etag, key: key).first_or_initialize
      self.data_source = HmisExternalApis::AcHmis.data_source
      self.dir = dir
    end

    def run!
      start
      sanity_check
      ProjectsImportAttempt.transaction do
        upsert_funders
        upsert_orgs
        upsert_projects
        upsert_walkins
      end
      analyze
      finish
    rescue AbortImportException => e
      @notifier.ping('Failure in project importer', { exception: e })
      Rails.logger.fatal e.message
    end

    def start
      setup_notifier('HMIS Projects')
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.current
      attempt.status = ProjectsImportAttempt::STARTED
      attempt.save!
    end

    def sanity_check
      return unless Dir.glob("#{dir}/*csv").empty?

      msg = "No csv files were found in #{attempt.key}"
      Rails.logger.error(msg)
      attempt.attempted_at = Time.now
      attempt.status = ProjectsImportAttempt::FAILED
      attempt.result = { error: msg }
      attempt.save!
      raise AbortImportException, msg
    end

    def upsert_funders
      generic_upsert(
        file: 'Funder.csv',
        conflict_target: ['"FunderID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Funder,
      )
    end

    def upsert_orgs
      generic_upsert(
        file: 'Organization.csv',
        conflict_target: ['"OrganizationID"', 'data_source_id'],
        klass: GrdaWarehouse::Hud::Organization,
      )
    end

    def upsert_projects
      @project_result = generic_upsert(
        file: 'Project.csv',
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
            when 'Y' then true
            when 'N' then false
            end,
        )
      end
    end

    def analyze
      Rails.logger.info 'Analyzing imported tables'
      ProjectsImportAttempt.connection.exec_query('ANALYZE "Funder", "Project", "Organization", "CustomDataElements";')
    end

    def finish
      attempt.status = ProjectsImportAttempt::SUCCEEDED
      attempt.save!
    end

    def records_from_csv(file)
      io = File.open(file, 'r')

      # Checking for BOM
      if io.read(3).bytes == [239, 187, 191]
        Rails.logger.info 'Byte-order marker (BOM) found. Skipping it.'
      else
        io.rewind
      end

      CSV.parse(io.read, headers: true, skip_lines: /\A\s*\z/)
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
