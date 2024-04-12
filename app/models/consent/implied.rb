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
    consent_type = full_consent_string if @client.active_consent_form&.consent_type == full_release_string
    consent_type = revoked_consent_string if @client.newest_consent_form&.revoked?
    consent_type
  end

  def no_release_string
    'Implied Consent'
  end

  def full_consent_string
    'Expanded Consent'
  end

  def revoked_consent_string
    'Consent Revoked'
  end

  def partial_release_string
    'Implied Consent'
  end

  def full_release_string
    'Expanded Consent'
  end

  def release_current_status
    # TODO: COMPLETE THIS
    consent_text = @client.class.no_release_string
    consent_text = @client.class.full_consent_string if current_consent_type == full_release_string
    consent_text = @client.class.revoked_consent_string if current_consent_type == revoked_consent_string
    consent_text
  end

  def scope_for_residential_enrollments(user)
    va_revoked_consent = release_current_status == @client.class.revoked_consent_string

    permission = if va_revoked_consent
      :can_view_clients
    else
      :can_view_client_enrollments_with_roi
    end

    va_scope = @client.service_history_enrollments.
      entry.
      hud_residential
    va_scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: permission))
  end

  def scope_for_other_enrollments(user)
    va_revoked_consent = release_current_status == @client.class.revoked_consent_string

    permission = if va_revoked_consent
      :can_view_clients
    else
      :can_view_client_enrollments_with_roi
    end

    va_scope = @client.service_history_enrollments.
      entry.
      hud_non_residential
    va_scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: permission))
  end
end
