# mask PII attributes on the client record
class GrdaWarehouse::ClientPii
  attr_reader :user, :client

  def initialize(user:, client:)
    @user = user
    @client = client
  end

 #def self.from_client(user:, client:)
 #  self.new(user: user, adapter: adapter)
 #end

  def first_name
    name_part(client.first_name.presence)
  end

  def last_name
    name_part(client.last_name.presence)
  end

  def middle_name
    name_part(client.middle_name.presence)
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
    can_view_full_dob? ? client.dob : nil
  end

  def age
    GrdaWarehouse::Hud::Client.age(date: Date.current, dob: client.dob)
  end

  def ssn
    value = client.ssn.presence
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
    can_view_client_name? ? value : "#{value.slice(0)}#{substitute}"
  end
end
