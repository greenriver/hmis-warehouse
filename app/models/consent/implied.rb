###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Consent::Implied
  def initialize(client:)
    @client = client
  end

  private def current_consent_type
    consent_type = no_release_string
    consent_type = full_release_string if @client.active_consent_form&.consent_type == full_release_string
    consent_type = revoked_consent_string if @client.newest_consent_form&.revoked?
    consent_type
  end

  def self.no_release_string
    'Implied Consent'
  end

  def no_release_string
    self.class.no_release_string
  end

  def self.revoked_consent_string
    'Consent Revoked'
  end

  def revoked_consent_string
    self.class.revoked_consent_string
  end

  def self.partial_release_string
    no_release_string
  end

  def partial_release_string
    self.class.partial_release_string
  end

  def self.full_release_string
    'Expanded Consent'
  end

  def full_release_string
    self.class.full_release_string
  end

  def self.release_string_query
    GrdaWarehouse::Hud::Client.arel_table[:housing_release_status].in([full_release_string, partial_release_string])
  end

  def release_current_status
    consent_text = no_release_string
    consent_text = full_release_string if current_consent_type == full_release_string
    consent_text = revoked_consent_string if current_consent_type == revoked_consent_string
    consent_text
  end

  def scope_for_residential_enrollments(user)
    revoked_consent = release_current_status == revoked_consent_string

    permission = if revoked_consent
      :can_view_clients
    else
      :can_view_client_enrollments_with_roi
    end

    scope = @client.service_history_enrollments.
      entry.
      hud_residential
    scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: permission))
  end

  def scope_for_other_enrollments(user)
    revoked_consent = release_current_status == revoked_consent_string

    permission = if revoked_consent
      :can_view_clients
    else
      :can_view_client_enrollments_with_roi
    end

    scope = @client.service_history_enrollments.
      entry.
      hud_non_residential
    scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: permission))
  end
end
