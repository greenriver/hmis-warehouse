###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Bag of PII accessors. Attributes are masked conditionally based on the policy
class GrdaWarehouse::PiiProvider
  attr_reader :policy, :record

  NAME_REDACTED = 'Name Redacted'.freeze
  REDACTED = 'Redacted'.freeze

  def self.viewable_name(value, policy:, replacement: REDACTED)
    return replacement unless policy.can_view_client_name?

    value.presence
  end

  def self.viewable_dob(value, policy:, replacement: REDACTED)
    return replacement unless policy.can_view_full_dob?

    value.presence
  end

  # record may be a Client or PiiProviderRecordAdapter
  def initialize(record, policy:)
    @policy = policy
    @record = record
  end

  PiiProviderRecordAdapter = Struct.new(:first_name, :last_name, :middle_name, :ssn, :dob, :image, keyword_init: true)
  private_constant :PiiProviderRecordAdapter

  # use when you don't have a client model, only ids (for example in reporting)
  # GrdaWarehouse::PiiProvider.from_attributes(policy: client_policy, dob: client_dob)
  def self.from_attributes(policy: nil, first_name: nil, last_name: nil, middle_name: nil, dob: nil, ssn: nil, image: nil)
    record = PiiProviderRecordAdapter.new(
      first_name: first_name,
      last_name: last_name,
      middle_name: middle_name,
      dob: dob,
      ssn: ssn,
      image: image,
    )
    new(record, policy: policy)
  end

  def first_name
    return name_redacted unless policy.can_view_client_name?

    record.first_name.presence
  end

  def last_name
    return name_redacted unless policy.can_view_client_name?

    record.last_name.presence
  end

  def middle_name
    return name_redacted unless policy.can_view_client_name?

    record.middle_name.presence
  end

  def full_name
    return name_redacted unless policy.can_view_client_name?

    [record.first_name, record.middle_name, record.last_name].compact.join(' ').presence
  end

  def brief_name
    return name_redacted unless policy.can_view_client_name?

    [record.first_name, record.last_name].compact.join(' ').presence
  end

  def dob_or_age
    dob&.strftime(Date::DATE_FORMATS[:default]) || age&.to_s
  end

  def dob_and_age(force_year_only: false)
    return nil unless record.dob

    display_dob = record.dob
    display_dob = display_dob&.year if force_year_only || !policy.can_view_full_dob?

    "#{display_dob} (#{age})"
  end

  # return nil rather than 'redacted' for consistent return type
  def dob
    policy.can_view_full_dob? ? record.dob : nil
  end

  # return nil rather than 'redacted' for consistent return type
  def age
    GrdaWarehouse::Hud::Client.age(date: Date.current, dob: record.dob)
  end

  def ssn(force_mask: false)
    value = record.ssn.presence
    mask = force_mask || !policy.can_view_full_ssn?
    format_ssn(value, mask: mask) if value
  end

  # @return [String, nil] (client.image is a string)
  def image
    return '' unless image?

    image_content
  end

  # Because the string is actually binary, calling .present? or presence on it
  # will throw an error.  Use .image? instead
  def image?
    # using length > 100 instead of present?  present? doesn't like
    # some UTF-8/binary
    (image_content || '').length > 100
  end

  protected

  def image_content
    @image_content ||= if policy.can_view_client_photo?
      record.image
    else
      ''
    end
  end

  def format_ssn(value, mask: true)
    padded_ssn = pad_ssn(value)
    mask ? format_masked_ssn(padded_ssn) : format_full_ssn(padded_ssn)
  end

  # Pad SSN with leading zeros to ensure it is 9 digits long
  def pad_ssn(value)
    value.rjust(9, '0')
  end

  SSN_RGX = HudUtility2024::SSN_RGX
  private_constant :SSN_RGX

  def format_masked_ssn(value)
    value.gsub(SSN_RGX, 'XXX-XX-\3').slice(0, 11)
  end

  def format_full_ssn(value)
    value.gsub(SSN_RGX, '\1-\2-\3')
  end

  def name_redacted
    NAME_REDACTED
  end
end
