# mask PII attributes on the client record
class GrdaWarehouse::ClientPii
  attr_reader :user, :record

  def initialize(record, user: nil)
    @user = user
    @record = record
  end

  ClientPiiRecordAdapter = Struct.new(:first_name, :last_name, :middle_name, :ssn, :dob, keyword_init: true)

  # GrdaWarehouse::ClientPii.from_attributes(user: current_user, dob: dob)
  def self.from_attributes(user: nil, first_name: nil, last_name: nil, middle_name: nil, dob: nil, ssn: nil)
    record = ClientPiiRecordAdapter.new(
      first_name: first_name,
      last_name: last_name,
      middle_name: middle_name,
      dob: dob,
      ssn: ssn,
    )
    new(record, user: user)
  end

  def first_name
    name_part(record.first_name)
  end

  def last_name
    name_part(record.last_name)
  end

  def middle_name
    name_part(record.middle_name)
  end

  def full_name
    [first_name, middle_name, last_name].compact.join(' ').presence
  end

  def brief_name
    [first_name, last_name].compact.join(' ').presence
  end

  def dob_or_age
    dob&.strftime(Date::DATE_FORMATS[:default]) || age&.to_s
  end

  def dob
    can_view_full_dob? ? record.dob : nil
  end

  def age
    GrdaWarehouse::Hud::Client.age(date: Date.current, dob: record.dob)
  end

  def ssn
    value = record.ssn.presence
    format_ssn(value, mask: !can_view_full_ssn?) if value
  end

  protected

  delegate :can_view_full_dob?, :can_view_full_ssn?, :can_view_client_name?, to: :user, allow_nil: true

  SSN_RGX = /(\d{3})[^\d]?(\d{2})[^\d]?(\d{4})/
  def format_ssn(value, mask: true)
    # pad with leading 0s if we don't have enough characters
    value = value.rjust(9, '0')
    if mask
      value.gsub(SSN_RGX, 'XXX-XX-\3')
    else
      value.gsub(SSN_RGX, '\1-\2-\3')
    end
  end

  def name_part(value, substitute: '*****')
    return nil unless value.present?

    can_view_client_name? ? value : "#{value.slice(0)}#{substitute}"
  end
end
