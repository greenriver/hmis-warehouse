# frozen_string_literal: true

require 'rubyXL'

class HmisExternalApis::AcHmis::Importers::HousingAssessmentImporter
  def self.call(...) = new.call(...)

  def call(filename, ce_project_id:, dry_run: true)
    raise 'Missing AC HMIS MCI credentials' unless mci.creds

    with_tx_lock do
      @ce_project_id = ce_project_id
      raw_rows = read_file_rows(filename)
      column_names = raw_rows.shift.map { |col| col.to_s.downcase.strip }
      raise unless column_names.sort == COLUMN_NAMES.sort # allow any order

      waitlists = build_waitlists(raw_rows, column_names)
      waitlists.each do |waitlist|
        enrollment = create_ce_enrollment(waitlist)
        ensure_intake_assessment!(enrollment)
        assessment = create_housing_assessment(waitlist, enrollment)
        complete_assessment(waitlist, assessment)
        log_info("Processed row #{waitlist.row_number}. HUD ID: #{waitlist.hud_id}, enrollment_id: #{enrollment.id}")
      end
      raise ActiveRecord::Rollback if dry_run
    end
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

  def create_form_processor(_waitlist, assessment)
    form_processor = assessment.build_form_processor
    form_processor.definition = form_definition
    form_processor.save!
  end

  def complete_assessment(waitlist, assessment)
    household_type = waitlist.household_type
    # Build an array of [cded_key, value] tuples to support repeated keys (multi-valued CDEs)
    tuples = []

    tuples << ['housing_needs_chronically_homeless', waitlist.chronically_homeless]
    tuples << ['housing_needs_aha_score', waitlist.aha_score]
    tuples << ['housing_needs_alternative_assessment_score', waitlist.alt_aha_score]
    tuples << ['housing_needs_ami', waitlist.income_percentage_ami]
    waitlist.referred_bedroom_sizes.each do |v|
      tuples << ['housing_needs_preferred_bedroom_size', v]
    end
    tuples << ['housing_needs_household_composition', household_type]
    tuples << ['housing_needs_transition_aged_youth', waitlist.tay]
    tuples << ['housing_needs_monthly_household_income', waitlist.infer_monthly_household_income]
    tuples << ['housing_needs_fpl', waitlist.income_percentage_fpl]
    tuples << ['housing_needs_number_of_household_members', waitlist.number_of_household_members]
    tuples << ['housing_needs_eligible_for_projects_serving_gender', waitlist.eligible_for_projects_serving_gender]
    tuples << ['housing_needs_any_household_income', waitlist.any_household_income]

    # attrs that need translation based on waitlist type
    [
      [
        'housing_needs_military_service',
        'anyone_in_household_service_in_military',
      ],
      [
        'housing_needs_megans_law',
        'anyone_in_household_megans_law',
      ],
      [
        'housing_needs_living_with_disability',
        'anyone_in_household_disability',
      ],
      [
        'housing_needs_living_with_hiv_aids',
        'anyone_in_household_hiv_aids',
      ],
      [
        'housing_needs_mental_health_diagnosis',
        'anyone_in_household_mental_health',
      ],
      [
        'housing_needs_substance_use_disorder',
        'anyone_in_household_substance_use',
      ],
      [
        'housing_needs_wheelchair_accessible_unit',
        'anyone_in_household_needs_wheelchair_accessible_unit',
      ],
      [
        'housing_needs_currently_pregnant',
        'anyone_in_household_pregnant',
      ],
    ].each do |cded_base_name, column|
      suffix = household_type == 'Individual' ? 'individual' : 'household'

      value = waitlist.public_send(column)
      tuples << ["#{cded_base_name}_#{suffix}", value]
      tuples << [cded_base_name.to_s, value]
    end

    tuples.reject { |(_k, v)| v.nil? }.each do |cded_field, value|
      cded = cded_lookup[cded_field]
      raise KeyError, "Missing CDED for key=#{cded_field.inspect}" unless cded

      cde = assessment.custom_data_elements.build(
        data_element_definition: cded,
        user: system_hud_user,
        data_source_id: assessment.data_source_id,
      )
      value_field_name = "value_#{cded.field_type}"
      cde[value_field_name] = value
      cde.save!
    end
  end

  def create_housing_assessment(waitlist, enrollment)
    assessment = enrollment.custom_assessments.new

    assessment.attributes = {
      user_id: system_hud_user.user_id,
      data_collection_stage: 99,
      date_created: waitlist.date_created,
      date_updated: waitlist.date_updated,
      assessment_date: waitlist.assessment_date,
      form_definition_identifier: form_definition.identifier,
      data_source: hmis_data_source,
    }
    assessment.save!
    create_form_processor(waitlist, assessment)
    assessment
  end

  def create_ce_enrollment(waitlist)
    hmis_client = find_and_update_hmis_client(waitlist) || create_hmis_client(waitlist)
    deterministic_id = waitlist.hud_id

    # remove existing enrollment if it exists
    hmis_ce_project.enrollments.
      where(client: hmis_client).
      where(enrollment_id: deterministic_id).
      each(&:really_destroy!) # can't soft-delete as unique constraint doesn't deal with that

    enrollment = hmis_ce_project.enrollments.new(
      client: hmis_client,
      entry_date: waitlist.assessment_date,
      user_id: system_hud_user.user_id,
      household_id: deterministic_id,
      enrollment_id: deterministic_id,
      date_created: waitlist.date_created,
      date_updated: waitlist.date_updated,
    )
    enrollment.save_new_enrollment! # handles auto enter
    enrollment
  end

  def ensure_intake_assessment!(enrollment)
    return if enrollment.intake_assessment.present?

    intake = enrollment.build_synthetic_intake_assessment
    intake.save!
  end

  def find_and_update_hmis_client(waitlist)
    # client_id is the MCI Unique ID
    mci_scope = HmisExternalApis::ExternalId.
      where(namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE).
      where(value: waitlist.client_id)

    client = Hmis::Hud::Client.joins(:ac_hmis_mci_unique_id).merge(mci_scope).first
    return nil unless client

    client.update!(**client_attrs(waitlist))
    client
  end

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

  def create_hmis_client(waitlist)
    client = Hmis::Hud::Client.create!(
      personal_id: waitlist.hud_id,
      data_source: hmis_data_source,
      **client_attrs(waitlist),
    )

    HmisExternalApis::AcHmis::Mci.external_ids.create!(
      namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
      value: waitlist.client_id,
      source: client,
      remote_credential: mci.creds,
    )
    client
  end

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
    @form_definition ||= Hmis::Form::Definition.published.where(identifier: 'housing_needs_assessment_2_0_individuals').first!
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

  def mci
    @mci ||= HmisExternalApis::AcHmis::Mci.new
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
    'assessment_date',
    'chronically_homeless',
    'aha_score',
    'alt_aha_score',
    'anyone_in_household_service_in_military',
    'anyone_in_household_megans_law',
    'anyone_in_household_disability',
    'anyone_in_household_hiv_aids',
    'anyone_in_household_mental_health',
    'anyone_in_household_substance_use',
    'anyone_in_household_needs_wheelchair_accessible_unit',
    'anyone_in_household_pregnant',
    'income_percentage_ami',
    'income_percentage_fpl',
    'referred_bedroom_sizes',
    'household_composition',
    'tay',
    'household_size',
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

    AMI_MONTHLY_100PCT = {
      1 => 6258.33,
      2 => 7150.0,
      3 => 8050.0,
      4 => 8941.67,
      5 => 9658.33,
      6 => 10375.0,
      7 => 11083.33,
      8 => 11800.0,
      9 => 12516.67,
      10 => 13233.33,
      11 => 13950.0,
      12 => 14666.67,
      13 => 15383.33,
      14 => 16091.67,
      15 => 16808.33,
      16 => 17525.0,
      17 => 18241.67,
      18 => 18958.33,
      19 => 19666.67,
      20 => 20383.33,
    }.freeze

    FPL_MONTHLY_100PCT = {
      1 => 1304.0,
      2 => 1763.0,
      3 => 2221.0,
      4 => 2679.0,
      5 => 3138.0,
      6 => 3596.0,
      7 => 4054.0,
      8 => 4513.0,
      9 => 4971.0,
      10 => 5429.0,
      11 => 5888.0,
      12 => 6346.0,
      13 => 6804.0,
      14 => 7263.0,
      15 => 7721.0,
      16 => 8179.0,
      17 => 8637.0,
      18 => 9096.0,
      19 => 9554.0,
      20 => 10012.0,
    }.freeze

    def infer_monthly_household_income
      size = number_of_household_members
      return nil if size.nil? || size <= 0

      size = [[size, 1].max, 20].min
      ami_base = AMI_MONTHLY_100PCT[size]
      fpl_base = FPL_MONTHLY_100PCT[size]

      ami_pct = to_number(raw_values.income_percentage_ami)
      fpl_pct = to_number(raw_values.income_percentage_fpl)

      # If no useful percentages, bail out
      return nil if ami_pct.nil? && fpl_pct.nil?

      # AMI-only fallback
      if fpl_pct.nil? || fpl_base.nil?
        return 0.0 unless ami_pct.to_f.positive?

        return round_currency((ami_pct / 100.0) * ami_base)
      end

      # FPL-only fallback
      if ami_pct.nil? || ami_base.nil?
        return 0.0 unless fpl_pct.to_f.positive?

        return round_currency((fpl_pct / 100.0) * fpl_base)
      end

      # Build income intervals that would round to the given integer percentages
      ami_lower = ((ami_pct - 0.5) / 100.0) * ami_base
      ami_upper = ((ami_pct + 0.5) / 100.0) * ami_base
      fpl_lower = ((fpl_pct - 0.5) / 100.0) * fpl_base
      fpl_upper = ((fpl_pct + 0.5) / 100.0) * fpl_base

      lower = [ami_lower, fpl_lower].max
      upper = [ami_upper, fpl_upper].min

      if lower <= upper
        candidate = round_currency((lower + upper) / 2.0)

        # Nudge inside if floating point rounding lands slightly out-of-range
        return candidate unless !matches_pct?(candidate, ami_base, ami_pct) || !matches_pct?(candidate, fpl_base, fpl_pct)

        # Try endpoints before falling back
        [lower, upper].each do |edge|
          cand = round_currency(edge)
          return cand if matches_pct?(cand, ami_base, ami_pct) && matches_pct?(cand, fpl_base, fpl_pct)
        end

      end

      # As a last resort, return AMI-only estimate
      round_currency((ami_pct / 100.0) * ami_base)
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

    def household_type
      # while there are multiple values, "Households with Children|Households without Children" - these appears to be individuals
      return 'Individual' if number_of_household_members == 1

      case raw_values.household_composition
      when 'Households without Children'
        'Household without minors'
      when 'Households with Children'
        'Household with minors'
      else
        raise "invalid #{raw_values.household_composition}"
      end
    end

    def number_of_household_members
      size = raw_values.household_size.to_i
      return nil if size <= 0

      [[size, 1].max, 20].min
    end

    def eligible_for_projects_serving_gender
      return nil unless household_type == 'Individual'

      code = parse_common_desc(raw_values.gender_common_desc)
      # note, our current form has mismatched cases "Identifying" vs "identifying"
      code == '2' ? 'Only Those Identifying as Female' : 'Only Those identifying as Male'
    end

    def any_household_income
      income = infer_monthly_household_income
      return nil if income.nil?

      income.to_f > 0 ? 'Yes' : 'No'
    end

    delegate(
      :client_id,
      :client_first_name,
      :client_last_name,
      :chronically_homeless,
      :aha_score,
      :alt_aha_score,
      :anyone_in_household_service_in_military,
      :anyone_in_household_megans_law,
      :anyone_in_household_disability,
      :anyone_in_household_hiv_aids,
      :anyone_in_household_mental_health,
      :anyone_in_household_substance_use,
      :anyone_in_household_needs_wheelchair_accessible_unit,
      :anyone_in_household_pregnant,
      :income_percentage_ami,
      :income_percentage_fpl,
      :tay,
      to: :raw_values,
    )

    def date_created = parse_date_time(raw_values.date_created)
    def date_updated = parse_date_time(raw_values.date_updated)
    def assessment_date = parse_date(raw_values.assessment_date)
    def client_dob = parse_date(raw_values.client_dob)
    def client_ssn_data_quality = data_quality(raw_values.ssn_data_quality)
    def client_dob_data_quality = data_quality(raw_values.dob_data_quality)

    def referred_bedroom_sizes
      raw_values.referred_bedroom_sizes.to_s.split(/\s*\|\s*/).compact_blank.map do |size|
        size = size.strip
        case size
        when '1', '2', '3', '4'
          "#{size} Bed"
        else
          # SRO, 0, 5, and x+crib are not supported but we store them anyway
          size
        end
      end.compact.uniq.sort
    end

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

    private

    def to_number(value)
      return nil if value.nil?

      val = value.is_a?(String) ? value.strip : value
      return nil if val == ''

      val.to_f
    end

    def percent_of_base(percent_value, base)
      pct = percent_value.to_f
      (pct / 100.0) * base.to_f
    end

    def round_currency(amount)
      ((BigDecimal(amount.to_s) * 100).round(0) / 100).to_f
    end

    def matches_pct?(income, base, expected_int_pct)
      ((income / base) * 100.0).round == expected_int_pct.to_i
    end
  end
end
