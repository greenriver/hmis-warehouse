require 'net/sftp'
require 'csv'
require 'charlock_holmes'

module Health::Tasks
  class ImportEpic
    include TsqlImport
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config, :logger

    # if load_locally, then the files must be in 'var/health'
    def initialize(logger: Rails.logger, load_locally: false, configs: nil)
      setup_notifier('HealthImporter')

      @logger = logger

      @load_locally = load_locally

      @to_revoke = []
      @to_restore = []
      @new_patients = []
      @configs = configs
    end

    def run!
      @configs ||= YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      @configs.each do |_, config|
        @config = config
        ds = Health::DataSource.find_by(name: config['data_source_name'])
        @data_source_id = ds.id
        fetch_files() unless @load_locally
        import_files()
        update_consent()
        sync_epic_pilot_patients()
        return change_counts()
      end
    end

    # This does not remove any data coming from EPIC, only upsirt
    def import klass:, file:
      path = "#{@config['destination']}/#{file}"
      handle = read_csv_file(path: path)
      if ! header_row_matches(file: handle, klass: klass)
        msg = "Incorrect file format for #{file}"
        notify msg
        raise msg
      end
      clean_values = []
      instance = klass.new # need an instance to cache some queries
      CSV.open(path, 'r:bom|utf-8', headers: true).each do |row|
        row = instance.clean_row(row: row, data_source_id: @data_source_id)
        clean_values << row.to_h.map do |k,v|
          clean_key = klass.csv_map[k.to_sym]
          [clean_key, klass.clean_value(clean_key, v)]
        end.to_h.except(nil).merge(data_source_id: @data_source_id)
      end
      count_incoming = clean_values.size
      count_existing = klass.count
      if above_acceptable_change_threshold(klass, count_incoming, count_existing)
        msg = "ALERT: Refusing to import #{klass.name} change is too great.  Incoming: #{count_incoming} Existing: #{count_existing}"
        notify msg
        return
      end

      klass.transaction do
        klass.delete_all
        insert_batch klass, clean_values.first.keys, clean_values.map(&:values), transaction: false, batch_size: 500
      end
    end

    # currently just a 10% change will prevent import/deletion
    # always allow import if we don't have any in the warehouse
    def above_acceptable_change_threshold klass, incoming, existing
      return false if existing == 0
      ((incoming - existing).abs.to_f / existing) > 0.1
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

    # only valid for pilot patients
    def update_consent
      klass = Health::EpicPatient
      file = Health.model_to_filename(klass)
      path = "#{@config['destination']}/#{file}"

      consented = klass.pilot.consented.pluck(:id_in_source)
      revoked = klass.pilot.consent_revoked.pluck(:id_in_source)
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

    # keep pilot patients in sync with epic export
    def sync_epic_pilot_patients
      Health::EpicPatient.pilot.each do |ep|
        patient = Health::Patient.where(id_in_source: ep.id_in_source, data_source_id: ep.data_source_id).first_or_create
        attributes = ep.attributes.select{|k,_| k.to_sym.in?(Health::EpicPatient.csv_map.values)}
        patient.update(attributes)
      end
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
      if klass.name == "Health::EpicCaseNote"
        (expected - found).size == 0
      else
        found == expected
      end
    end

    def notify msg
      @logger.info msg
      @notifier.ping msg if @send_notifications
    end
  end
end
