# frozen_string_literal: true

require 'rubyXL'

class HmisExternalApis::AcHmis::Importers::WaitlistHouseholdMembersImporter
  def self.call(...) = new.call(...)

  def call(filename, ce_project_id:, form_definition_identifier:, dry_run: true)
    raise 'Missing AC HMIS MCI credentials' unless mci_creds
    raise 'Missing AC HMIS MCI Unique ID credentials' unless mci_uniq_creds

    with_tx_lock do
      @ce_project_id = ce_project_id
      @form_definition_identifier = form_definition_identifier
      raw_rows = read_file_rows(filename)
      column_names = raw_rows.shift.map { |col| col.to_s.downcase.strip }
      raise unless column_names.sort == COLUMN_NAMES.sort # allow any order

      waitlists = build_waitlists(raw_rows, column_names)

      waitlists.group_by(&:household_id).each do |household_id, household_members|
        next if waitlists.size == 1 # skip single-member households, they should already have been processed

        hoh_row = household_members.find(&:hoh?)
        raise "No HoH found for household #{household_id}" unless hoh

        # Find the HoH Enrollment in the CE project. It should exist because it should have been created
        # by the HousingAssessmentImporter on 10/1 import.
        # TODO: have the job accept a flag for whether to raise or skip if not found. We may want to skip these (after investigating)
        hoh_enrollment = find_hoh_enrollment(hoh_row, raise_on_missing: true)
        next unless hoh_enrollment

        # Skip if the household already has multiple members. This indicates that a user has already manually updated the household,
        # so we shouldn't mess with the household composition at all.
        if hoh_enrollment.household_members.size > 1
          log_info("Household #{household_id} (HouseholdID: #{hoh_enrollment.household_id}) already has multiple members. Skipping to avoid creating duplicate enrollments, since a user has already manually updated the household.")
          next
        end

        # Create enrollments for each household member (Excluding HoH).
        # This process will look for existing clients, and create them if needed.
        household_members.reject(&:hoh?).each do |row|
          enrollment = create_ce_enrollment(row, hoh_enrollment: hoh_enrollment)
          ensure_intake_assessment!(row, enrollment)
          log_info("Processed row #{row.row_number}. HUD ID: #{row.hud_id}, enrollment_id: #{enrollment.id}")
        end
      end
      raise ActiveRecord::Rollback if dry_run
    end
    log_info 'Import complete'
  end

  protected

  def build_waitlists(rows, header_row)
    by_client_id = {}

    rows.each_with_index do |row_values, idx|
      row_number = idx + 2
      next if row_values.compact.blank?

      raise "Row #{row_number} has #{row_values.size} columns; expected #{header_row.size}" if row_values.size != header_row.size

      attrs = header_row.zip(row_values).to_h.symbolize_keys
      waitlist = Waitlist.new(attrs, row_number: row_number)
      raise "Row #{row_number} is invalid" unless waitlist.valid?

      client_id = waitlist.client_id
      existing = by_client_id[client_id]
      if existing.nil?
        by_client_id[client_id] = waitlist
      else
        # Keep the waitlist with the most recent assessment_date
        existing_date = existing.assessment_date
        new_date = waitlist.assessment_date
        by_client_id[client_id] = waitlist if new_date && (!existing_date || new_date > existing_date)
      end
    end

    by_client_id.values
  end

  # NEW
  def find_hoh_enrollment(waitlist, raise_on_missing: true)
    # Try to find corresponding enrollment in the CE project.
    # Look up by PersonalID because the HousingAssessmentImporter set a deterministic value for PersonalID. (See "hud_id" method and "create_hmis_client" method.)
    found_enrollment = hmis_ce_project.enrollments.
      heads_of_households.
      where(personal_id: waitlist.hud_id). # hud_id = Digest::MD5.hexdigest(raw_values.client_id.to_s)
      max_by(&:entry_date)

    return found_enrollment if found_enrollment

    log_info("No enrollment found for HoH on row #{waitlist.row_number}, client_id: #{waitlist.client_id}. Skipping.")
    raise "No enrollment found for HoH on row #{waitlist.row_number}" if raise_on_missing
  end

  # NEW
  def create_ce_enrollment(waitlist, hoh_enrollment:)
    hmis_client = find_hmis_client(waitlist) || create_hmis_client(waitlist)
    deterministic_id = waitlist.hud_id # based on client_id

    # Check if client is already enrolled in the CE project. We don't want to create duplicate enrollments
    already_enrolled = hmis_ce_project.enrollments.open_on_date.
      where(client: hmis_client).exists?
    raise "Client #{hmis_client.id} already has an open enrollment in the project" if already_enrolled

    enrollment = hmis_ce_project.enrollments.new(
      client: hmis_client,
      entry_date: waitlist.assessment_date,
      user_id: system_hud_user.user_id,
      household_id: hoh_enrollment.household_id,
      relationship_to_hoh: waitlist.relationship_to_hoh,
      enrollment_id: deterministic_id,
      date_created: waitlist.date_created,
      date_updated: waitlist.date_updated,
      project_id: hmis_ce_project.project_id,
      source_hash: 'WAITLIST_HOUSEHOLD_MEMBERS_IMPORTER', # to help identify these if we need to clean them up. maybe unset after import is done and validated
    )
    enrollment.save!
  end

  def ensure_intake_assessment!(waitlist, enrollment)
    return if enrollment.intake_assessment.present?

    intake = enrollment.build_synthetic_intake_assessment
    intake.date_created = waitlist.date_created
    intake.date_updated = waitlist.date_updated
    intake.save!
  end

  # COPIED FROM HousingAssessmentImporter, no changes needed!
  def find_hmis_client(waitlist)
    # client_id is the MCI Unique ID
    mci_scope = HmisExternalApis::ExternalId.
      where(namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE).
      where(value: waitlist.client_id)

    client = Hmis::Hud::Client.joins(:ac_hmis_mci_unique_id).merge(mci_scope).first
    if client
      log_info("Found client with MCI Unique ID #{waitlist.client_id}: #{client.id}")
      return client
    end

    # If not found by MCI Unique ID, look up by MCI ID. This would be needed if the client exists in HMIS
    # because they were referred from LINK, but they don't have an MCI Unique ID. When Link sends a referral
    # "posting" for a new client, we generate a new Client record with an MCI ID. We don't create an MCI Unique ID at that time,
    # and the MCI Unique ID won't get created until/unless the client has any enrollments. (Unenrolled clients
    # are not exported in HMIS export, so Data Warehouse API won't provide MCI Unique IDs for those clients.)
    found_mci_ids = HmisExternalApis::ExternalId.mci_ids.where(value: waitlist.client_mci_id).to_a
    return nil unless found_mci_ids.size == 1 # if multiple, can't be sure which one to update, don't use

    client = found_mci_ids.first.source
    return nil unless client.ac_hmis_mci_unique_id.nil? # if they already have an MCI Unique ID, don't use, something is off

    log_info("Found client with MCI ID #{waitlist.client_mci_id}: #{client.id}")
    client
  end

  # COPIED FROM HousingAssessmentImporter, no changes needed!
  def client_attrs(waitlist)
    {
      user: system_hud_user,
      first_name: waitlist.client_first_name,
      last_name: waitlist.client_last_name,
      ssn: waitlist.client_ssn,
      ssn_data_quality: waitlist.client_ssn_data_quality,
      dob: waitlist.client_dob,
      dob_data_quality: waitlist.client_dob_data_quality,
      veteran_status: waitlist.client_veteran_status,
      **waitlist.client_gender_fields,
      **waitlist.client_race_fields,
      **waitlist.client_ethnicity_fields,
    }
  end

  # COPIED FROM HousingAssessmentImporter, no changes needed!
  def create_hmis_client(waitlist)
    client = Hmis::Hud::Client.create!(
      personal_id: waitlist.hud_id,
      data_source: hmis_data_source,
      **client_attrs(waitlist),
    )

    # Create MCI Unique ID
    HmisExternalApis::AcHmis::Mci.external_ids.create!(
      namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
      value: waitlist.client_id,
      source: client,
      remote_credential: mci_uniq_creds,
    )
    # Create MCI ID
    HmisExternalApis::AcHmis::Mci.external_ids.create!(
      namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
      value: waitlist.client_mci_id,
      source: client,
      remote_credential: mci_creds,
    )

    log_info "Created client for MCI Unique ID #{waitlist.client_id}: #{client.id}"
    client
  end

  # COPIED FROM HousingAssessmentImporter, no changes needed!
  def hmis_ce_project
    raise 'CE project ID is required' if @ce_project_id.blank?

    @hmis_ce_project ||= Hmis::Hud::Project.
      where(id: @ce_project_id).
      where(data_source: hmis_data_source).
      sole
  end

  def hmis_data_source
    @hmis_data_source ||= GrdaWarehouse::DataSource.hmis.sole
  end

  def form_definition
    @form_definition ||= Hmis::Form::Definition.published.where(identifier: @form_definition_identifier).first!
  end

  def system_hud_user
    @system_hud_user ||= Hmis::Hud::User.system_user(data_source_id: hmis_data_source.id)
  end

  def read_file_rows(filename)
    workbook = ::RubyXL::Parser.parse(filename)
    workbook.worksheets[0].map do |row|
      row.cells.map { |cell| cell&.value }
    end
  end

  def with_tx_lock
    lock_name = self.class.name
    Hmis::HmisBase.with_advisory_lock(lock_name, timeout_seconds: 0) do
      Hmis::HmisBase.transaction do
        yield
      end
    end
  end

  # Note: cred does not have to be active, to support running in lower environments where these integrations may be turned off
  def mci_creds
    @mci_creds ||= GrdaWarehouse::RemoteCredential.where(slug: HmisExternalApis::AcHmis::Mci::SYSTEM_ID).sole
  end

  def mci_uniq_creds
    @mci_uniq_creds ||= GrdaWarehouse::RemoteCredential.where(slug: HmisExternalApis::AcHmis::DataWarehouseApi::SYSTEM_ID).sole
  end

  def cded_lookup
    @cded_lookup ||= form_definition.custom_data_element_definitions.index_by(&:key)
  end

  COLUMN_NAMES = [
    'client_id', # unique mci id
    'client_dob',
    'client_first_name',
    'client_last_name',
    'client_mci_id', # non-unique mci id
    'date_created',
    'date_updated',
    # Assessment-related columns are ignored in this importer, we are only adding household member Clients/Enrollments
    # 'assessment_date',
    # 'chronically_homeless',
    # 'aha_score',
    # 'alt_aha_score',
    # 'anyone_in_household_service_in_military',
    # 'anyone_in_household_megans_law',
    # 'anyone_in_household_disability',
    # 'anyone_in_household_hiv_aids',
    # 'anyone_in_household_mental_health',
    # 'anyone_in_household_substance_use',
    # 'anyone_in_household_needs_wheelchair_accessible_unit',
    # 'anyone_in_household_pregnant',
    # 'income_percentage_ami',
    # 'income_percentage_fpl',
    # 'referred_bedroom_sizes',
    # 'household_composition',
    # 'tay',
    # 'household_size',
    'dob_data_quality',
    'ssn',
    'ssn_data_quality',
    'race_common_desc',
    'ethnic_common_desc',
    'gender_common_desc',
    'vetern_flag', # note, this is misspelled in the export
  ].freeze

  def log_info(msg)
    return puts msg if Rails.env.development?

    Rails.logger.info(msg)
  end

  Row = Struct.new(*COLUMN_NAMES.map(&:to_sym))
  class Waitlist
    attr_accessor :row_number, :raw_values

    def initialize(raw_values, row_number:)
      @raw_values = Row.new(**raw_values)
      @row_number = row_number
    end

    def valid?
      # basic sanity check
      raw_values.client_id.to_s.match?(/\A\d{5,}\z/) && raw_values.client_dob.to_s.match?(/\A[1-2]\d{3}-\d{2}-\d{2}\z/)
    end

    # repeatable personal id
    def hud_id = Digest::MD5.hexdigest(raw_values.client_id.to_s)

    def client_ssn
      value = raw_values.ssn
      return if value.blank?

      raise ArgumentError, "Integer too long for SSN (#{value.inspect})" if value.to_s.length > 9

      value.is_a?(String) ? value : format('%09d', value)
    end

    def client_veteran_status
      raw_values.vetern_flag&.strip&.downcase == 'yes' ? 1 : 0
    end

    def client_race_fields
      code = parse_common_desc(raw_values.race_common_desc)
      field = HmisExternalApis::AcHmis::MciMapping::MCI_RACE_TO_HUD_RACE[code]
      field ||= 'race_none'
      return { field => 1 } if field
    end

    def client_ethnicity_fields
      code = parse_common_desc(raw_values.ethnic_common_desc)
      {
        'hispanic_latinaeo' => code == '2' ? 0 : 1,
      }
    end

    def client_gender_fields
      value = raw_values.gender_common_desc
      code = parse_common_desc(value)
      if code == '2'
        { 'woman' => 1, 'man' => 0 }
      elsif code == '1'
        { 'man' => 1, 'woman' => 0 }
      else
        raise ArgumentError, "gender #{value} not supported"
      end
    end

    def hoh?
      relationship_to_hoh == 1
    end

    # Translate provided relationship type description into HUD RelationshipToHoH
    def relationship_to_hoh
      case raw_values.relationship_type_desc
      when 'Self'
        1 # Self (head of household)
      when 'Son', 'Daughter'
        2 # Child
      when 'Spouse/Partner'
        3 # Spouse or partner
      when 'Parent', 'Sister', 'Niece', 'Nephew', 'Grandchild'
        4 # Other relative
      when 'Friend'
        5 # Unrelated household member
      else
        raise "unexpected relationship type #{raw_values.relationship_type_desc}"
      end
    end

    delegate(
      :client_id,
      :client_first_name,
      :client_last_name,
      :chronically_homeless,
      :client_mci_id,
      # :anyone_in_household_service_in_military,
      # :anyone_in_household_megans_law,
      # :anyone_in_household_disability,
      # :anyone_in_household_hiv_aids,
      # :anyone_in_household_mental_health,
      # :anyone_in_household_substance_use,
      # :anyone_in_household_needs_wheelchair_accessible_unit,
      # :anyone_in_household_pregnant,
      # :income_percentage_ami,
      # :income_percentage_fpl,
      # :tay,
      to: :raw_values,
    )

    def date_created = parse_date_time(raw_values.date_created)
    def date_updated = parse_date_time(raw_values.date_updated)
    def assessment_date = parse_date(raw_values.assessment_date)
    def client_dob = parse_date(raw_values.client_dob)
    def client_ssn_data_quality = data_quality(raw_values.ssn_data_quality)
    def client_dob_data_quality = data_quality(raw_values.dob_data_quality)

    protected

    def data_quality(value)
      value = value&.to_i || 99

      raise "bad data quality #{value}" unless value.in?([1, 2, 8, 9, 99])

      value
    end

    def parse_date(value)
      case value
      when String
        Date.iso8601(value)
      when Date
        value
      else
        raise ArgumentError, "unknown date type #{value.inspect}"
      end
    end

    def parse_date_time(value)
      case value
      when String
        DateTime.parse(value)
      when DateTime
        value
      else
        raise ArgumentError, "unknown date type #{value.inspect}"
      end
    end

    def parse_common_desc(value)
      value ? value.split('~', 2)[0] : nil
    end
  end
end
