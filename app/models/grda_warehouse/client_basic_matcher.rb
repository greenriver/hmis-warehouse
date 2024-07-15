
class GrdaWarehouse::ClientBasicMatcher
  attr_accessor :ssn_format, :ids_by_name, :ids_by_ssn, :ids_by_dob, :records_by_id

  def initialize(ssn_format: :full)
    self.ssn_format = ssn_format
    self.ids_by_name = {}
    self.ids_by_ssn = {}
    self.ids_by_dob = {}
    self.records_by_id = {}
    build_lookups
  end

  def get_client_by_id(id)
    records_by_id[id]
  end

  def check_name(first_name:, last_name:)
    first_name = normalize_name_string(first_name)
    last_name = normalize_name_string(last_name)
    return EMPTY_SET unless first_name && last_name

    result(ids_by_name[[first_name, last_name]])
  end

  def check_social(ssn:)
    return EMPTY_SET unless valid_social?(ssn)

    result(ids_by_ssn[ssn])
  end

  def check_birthday(dob:)
    return EMPTY_SET unless dob

    result(ids_by_dob[dob])
  end

  protected

  def normalize_name_string(str)
    str ? str.downcase.strip.gsub(/[^a-z0-9]/i, '').presence : nil
  end

  def valid_social?(value)
    case ssn_format
    when :full
      ::HudUtility2024.valid_social?(value)
    when :last_four
      ::HudUtility2024.valid_last_four_social?(value)
    else
      raise
    end
  end

  EMPTY_SET = [].freeze
  def result(ary)
    ary.uniq || EMPTY_SET
  end

  def build_lookups
    GrdaWarehouse::Hud::Client.destination.in_batches(of: 5_000) do |batch|
      batch.pluck(:FirstName, :LastName, :SSN, :DOB, :id).each do |first_name, last_name, ssn, dob, id|
        add_name_lookup(first_name, last_name, id)
        add_dob_lookup(dob, id)
        add_ssn_lookup(ssn, id)
        add_record_by_id(ssn, dob, id)
      end
    end
  end

  def add_name_lookup(first_name, last_name, id)
    first_name = normalize_name_string(first_name)
    last_name = normalize_name_string(last_name)
    return unless first_name && last_name

    name_key = [first_name, last_name]
    ids_by_name[name_key] ||= []
    ids_by_name[name_key].push(id)
  end

  def add_record_by_id(ssn, dob, id)
    records_by_id[id] = {SSN: ssn, DOB: dob, id: id}
  end

  def add_dob_lookup(dob, id)
    return unless dob

    ids_by_dob[dob] ||= []
    ids_by_dob[dob].push(id)
  end

  def add_ssn_lookup(ssn, id)
    return unless ssn

    case ssn_format
    when :full
      key = ssn
    when :last_four
      key = ssn[-4..-1]
    else
      raise
    end

    return unless key

    ids_by_ssn[key] ||= []
    ids_by_ssn[key].push(id)
  end
end
