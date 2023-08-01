###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class CustomDataElementsImporter
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
      start
      sanity_check
      ProjectsImportAttempt.transaction do
        # import_referral_requests
        # import_referral_postings
        # import_referral_household_members
        import_esg_funding_assistance
      end
      analyze
      finish
    rescue AbortImportException => e
      @notifier.ping("Failure in #{importer_name}", { exception: e })
      Rails.logger.fatal e.message
      Rails.logger.fatal "#{importer_name} Aborted before it finished."
    end

    protected

    def import_referral_requests
      raise "tbd"
      file = 'ReferralRequests.csv'
    end

    # referrals and referral postings
    def import_referral_postings
      raise "tbd"

      file = 'ReferralPostings.csv'
      col_map = [
        ["identifier", 'postingId']
        # ["status", 'postingStatusId'], # fixme enum
        # ["referral_id", ], #fixme needs lookup
        # ["project_id"], mapping
        # "referral_request_id",
        # "unit_type_id",
        # "HouseholdID",
        # "resource_coordinator_notes",
        # "status_updated_at",
        # "status_updated_by_id",
        # "status_note",
        # "status_note_updated_by_id",
        # "denial_reason",
        # "referral_result",
        # "denial_note",
        # "status_note_updated_at",
        # "data_source_id"
      ]
      rows = records_from_csv(file).each do |csv_row|
        attrs = {}
        col_map.each do |attr, csv_col|
          attrs[attr] = csv_row.fetch(csv_col)
        end
        #
        # map status
        # map referral_id
        # map unit_type
        attrs
      end

      columns_to_update = rows.first.keys - ['identifier']
      result = HmisExternalApis::AcHmis::ReferralPosting.import!(
        records,
        validate: false,
        batch_size: 1_000,
        on_duplicate_key_update: {
          conflict_target: 'identifier',
          columns: columns_to_update,
        },
      )
    end

    def import_referral_household_members
      raise "tbd"
      file = 'ReferralHouseholdMembers.csv'
    end

    def import_esg_funding_assistance
      file = 'ESGFundingAssistance.csv'
    end

    def importer_name
      self.class.name
    end

    def start
      setup_notifier(importer_name)
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.current
      attempt.status = ProjectsImportAttempt::STARTED
      attempt.save!
    end

    def sanity_check
      msg = []
      [
        'ReferralPostings.csv',
        'ReferralHouseholdMembers.csv',
        'ReferralRequests.csv',
      ].each do |fn|
        msg << "#{fn} was not present." unless File.exist?("#{dir}/#{fn}")
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


    def analyze
      Rails.logger.info 'Analyzing imported tables'
      ProjectsImportAttempt.connection.exec_query('ANALYZE "Funder", "Project", "Organization", "CustomDataElements";')
    end

    def finish
      attempt.status = ProjectsImportAttempt::SUCCEEDED
      attempt.save!
    end

    def check_columns(file:, expected_columns:, critical_columns:, rows:)
      raise AbortImportException, "There was no data in #{file}." if rows.empty?

      keys = rows.first.to_h.keys

      missing_columns = expected_columns - keys
      missing_critical_columns = critical_columns - keys

      self.extra_columns = keys - expected_columns

      Rails.logger.warn("Skipping extra columns (#{extra_columns.join(', ')}) in #{file}") if extra_columns.present?

      raise(AbortImportException, "There were critical missing columns in #{file}: #{missing_critical_columns.join(', ')}.") if missing_critical_columns.present?

      Rails.logger.warn("There were non-critical missing columns in #{file}: #{missing_columns.join(', ')}.") if missing_columns.present?
    end

    def records_from_csv(file)
      io = File.open(file, 'r')

      # Checking for BOM
      if io.read(3).bytes == [239, 187, 191]
        Rails.logger.info 'Byte-order marker (BOM) found. Skipping it.'
      else
        io.rewind
      end

      CSV.parse(io.read, **csv_config)
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
