require 'net/sftp'
require 'csv'
require 'charlock_holmes'

module Health::Tasks
  class ImportEpic
    include TsqlImport
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config, :logger

    def initialize(logger: Rails.logger, load_locally: false)
      setup_notifier('HealthImporter')
      
      @logger = logger
            
      @load_locally = load_locally
      
      @to_revoke = []
      @to_restore = []
      @new_patients = []
    end

    def run!
      # TODO: Ansible and the .env will need to be updated when this is deployed
      configs = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      configs.each do |_, config|
        @config = config
        ds = Health::DataSource.find_by(name: config['data_source_name'])
        @data_source_id = ds.id
        fetch_files() unless @load_locally
        import_files()
        update_consent()
        return change_counts()
      end
    end

    def import klass:, file:
      path = "#{@config['destination']}/#{file}"
      handle = read_csv_file(path: path)
      if ! header_row_matches(file: handle, klass: klass)
        msg = "Incorrect file format for #{file}"
        notify msg
        raise msg
      end
      CSV.open(path, 'r:bom|utf-8', headers: true).each do |row|
      # CSV.foreach(path, 'r:bom|utf-8', headers: true) do |row|
        key = row[klass.source_key.to_s]
        translated_row = row.to_h.map do |k,v|
          clean_key = klass.csv_map[k.to_sym]
          [clean_key, klass.clean_value(clean_key, v)]
        end.to_h
        # Make note that the import of patients is only functional for the pilot
        if klass == Health::Patient
          translated_row[:pilot] = true
        end
        entry = klass.where(klass.csv_map[klass.source_key] => key, data_source_id: @data_source_id).
          first_or_create(translated_row) do |patient|
          if klass == Health::Patient
            @new_patients << patient[:id_in_source]
          end
        end
        changed = entry.updated_at < translated_row[:updated_at] rescue false
        if changed
          entry.update(translated_row)
        end
      end
    end

    def import_files
      Health.models_by_health_filename.each do |file, klass|
        import(klass: klass, file: file)
      end
    end

    def change_counts
      {
        new_patients: @new_patients.size,
        consented: @to_restore.size, 
        revoked_consent: @to_revoke.size,
      }
    end

    # def notify_health_admin_of_changes
    #   if @new_patients.size > 0 || @to_revoke.any? || @to_restore.any?
    #     User.can_administer_health.each do |user|
    #       HealthConsentChangeMailer.consent_changed(
    #         new_patients: @new_patients.size,
    #         consented: @to_restore.size, 
    #         revoked_consent: @to_revoke.size, 
    #         user: user
    #       ).deliver_later
    #     end 
    #   end
    # end

    def update_consent
      klass = Health::Patient
      file = Health.model_to_filename(klass)
      path = "#{@config['destination']}/#{file}"

      consented = klass.consented.pluck(:id_in_source)
      revoked = klass.consent_revoked.pluck(:id_in_source)
      incoming = []
      CSV.open(path, 'r:bom|utf-8', headers: true).each do |row|
        incoming << row[klass.source_key.to_s]
      end
      @to_revoke = consented - incoming
      @to_restore = revoked & incoming
      notify "Revoking consent for #{@to_revoke.size} patients"
      klass.where(id_in_source: @to_revoke).revoke_consent
      notify "Restoring consent for #{@to_restore.size} patients"
      klass.where(id_in_source: @to_restore).restore_consent
    end

    def fetch_files
      sftp = Net::SFTP.start(
        @config['host'], 
        @config['username'],
        password: @config['password'],
        # verbose: :debug,
        auth_methods: ['publickey','password']
      )
      sftp.download!(@config['path'], @config['destination'], recursive: true)

      notify "Health data downloaded"
    end

    def read_csv_file path:
      # Look at the file to see if we can determine the encoding
      @file_encoding = CharlockHolmes::EncodingDetector
        .detect(File.read(path))
        .try(:[], :encoding)
      file_lines = IO.readlines(path).size - 1
      @logger.info "Processing #{file_lines} lines in: #{path}"
      File.open(path, "r:bom|#{@file_encoding}")
    end

    def header_row_matches file:, klass:
      expected = klass.csv_map.keys.sort
      found = CSV.parse(file.first).first.map(&:to_sym).sort
      found == expected
    end

    def notify msg
      @logger.info msg
      @notifier.ping msg if @send_notifications
    end
  end
end
