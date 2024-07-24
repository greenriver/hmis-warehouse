###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Consent::Default
  def initialize(client:)
    @client = client
  end

  def self.no_release_string
    'None on file'
  end

  def no_release_string
    self.class.no_release_string
  end

  def self.revoked_consent_string
    ''
  end

  def revoked_consent_string
    self.class.revoked_consent_string
  end

  def self.partial_release_string
    'Limited CAS Release'
  end

  def partial_release_string
    self.class.partial_release_string
  end

  def self.full_release_string
    'Full HAN Release'
  end

  def full_release_string
    self.class.full_release_string
  end

  def self.release_string_query
    GrdaWarehouse::Hud::Client.arel_table[:housing_release_status].matches("%#{full_release_string}")
  end

  def release_current_status
    consent_text = if @client.housing_release_status.blank?
      no_release_string
    elsif @client.release_duration.in?(['One Year', 'Two Years'])
      if @client.consent_form_valid?
        "Valid Until #{@client.consent_form_signed_on + @client.class.consent_validity_period}"
      else
        'Expired'
      end
    elsif @client.release_duration == 'Use Expiration Date'
      if @client.consent_form_valid?
        "Valid Until #{@client.consent_expires_on}"
      else
        'Expired'
      end
    else
      Translation.translate(@client.housing_release_status)
    end
    consent_text += " in #{@client.consented_coc_codes.to_sentence}" if @client.consented_coc_codes&.any?
    consent_text
  end

  def scope_for_residential_enrollments(_user = nil)
    @client.service_history_enrollments.
      entry.
      hud_residential
  end

  def scope_for_other_enrollments(_user = nil)
    @client.service_history_enrollments.
      entry.
      hud_non_residential
  end
end
