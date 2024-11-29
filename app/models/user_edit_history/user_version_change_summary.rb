###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UserEditHistory::UserVersionChangeSummary
  # allow list of columns on the user table we can display to an admin. Excludes credentials and sessions
  VISIBLE_FIELDS_VALUES = [
    'active',
    'agency_id',
    'confirmation_sent_at',
    'confirmed_2fa',
    'confirmed_at',
    'consumed_timestep',
    'current_sign_in_at',
    'current_sign_in_ip',
    'deleted_at',
    'email',
    'email_schedule',
    'exclude_from_directory',
    'exclude_phone_from_directory',
    'expired_at',
    'failed_attempts',
    'first_name',
    'invitation_accepted_at',
    'invitation_created_at',
    'invitation_limit',
    'invitation_sent_at',
    'invitations_count',
    'invited_by_id',
    'invited_by_type',
    'last_activity_at',
    'last_name',
    'last_sign_in_at',
    'last_sign_in_ip',
    'last_training_completed',
    'locked_at',
    'notify_on_anomaly_identified',
    'notify_on_client_added',
    'notify_on_new_account',
    'notify_on_vispdat_completed',
    'otp_required_for_login',
    'password_changed_at',
    'permission_context',
    'phone',
    'receive_account_request_notifications',
    'receive_file_upload_notifications',
    'remember_created_at',
    'reset_password_sent_at',
    'sign_in_count',
    'superset_roles',
    'talent_lms_email',
    'training_completed',
    'training_courses',
    'unconfirmed_email',
    'updated_at',
  ].to_set.freeze

  # Define a constant to hold all the change summary patterns
  # Note, no need to include a condition for logins, those events are excluded from history
  ChangePattern = Struct.new(:value, :event, :match_keys, :match, keyword_init: true) do
    def matches?(version, changeset)
      return if event && event != version.event
      return if match_keys && match_keys != changeset.keys.sort
      return if match && !match.call(version, changeset)

      true
    end
  end
  CHANGE_PATTERNS = [
    ChangePattern.new(
      value: 'Account created',
      event: 'create',
      match: ->(version, _changeset) { version.event == 'create' },
    ),
    ChangePattern.new(
      value: 'Account deleted',
      event: 'destroy',
    ),
    # seems like we special case this in the users controller. Not sure why
    ChangePattern.new(
      value: 'Account deactivated',
      event: 'deactivate',
    ),
    ChangePattern.new(
      value: 'Invitation Sent',
      match_keys: ['invitation_created_at', 'invitation_sent_at', 'invitation_token', 'updated_at'],
      match: ->(_version, changeset) { changeset.dig('invitation_sent_at', 1).present? },
    ),
    ChangePattern.new(
      value: 'Account deactivated',
      event: 'update',
      match_keys: ['active', 'updated_at'],
      match: ->(_version, changeset) { !changeset.dig('active', 1) },
    ),
    ChangePattern.new(
      value: 'Account activated',
      event: 'update',
      match_keys: ['active', 'updated_at'],
      match: ->(_version, changeset) { changeset.dig('active', 1) },
    ),
    ChangePattern.new(
      value: 'Invitation accepted',
      event: 'update',
      match_keys: ['confirmed_at', 'encrypted_password', 'invitation_accepted_at', 'invitation_token', 'password_changed_at', 'updated_at'],
      match: ->(version, _changeset) { version.anonymous? },
    ),
    ChangePattern.new(
      value: 'Account reactivated',
      event: 'update',
      match_keys: ['active', 'encrypted_password', 'last_activity_at', 'password_changed_at', 'updated_at'],
      match: ->(version, _changeset) { !version.anonymous? && changeset.dig('active', 1) },
    ),
    ChangePattern.new(
      value: 'Password reset email sent',
      event: 'update',
      match_keys: ['reset_password_sent_at', 'reset_password_token', 'updated_at'],
      match: ->(_version, changeset) { changeset.dig('reset_password_token', 1).present? },
    ),
    ChangePattern.new(
      value: 'Password reset from forgot-password form',
      event: 'update',
      match_keys: ['encrypted_password', 'password_changed_at', 'reset_password_sent_at', 'reset_password_token', 'updated_at'],
      match: ->(version, changeset) { version.anonymous? && changeset.dig('reset_password_token', 1).blank? },
    ),
    ChangePattern.new(
      value: 'Password reset by user',
      event: 'update',
      match_keys: ['encrypted_password', 'password_changed_at', 'updated_at'],
      match: ->(version, _changeset) { !version.anonymous? },
    ),
  ].map(&:freeze).freeze

  def perform(version, changeset)
    Array.wrap(summary(version, changeset) || details(changeset)).presence
  end

  protected

  # try to concisely summarize common events
  def summary(version, changeset)
    CHANGE_PATTERNS.filter { |p| p.matches?(version, changeset) }.map(&:value)
  end

  def details(changeset)
    changeset.map do |field, values|
      next if field =~ /\A(id|updated_at|created_at)\z/

      from, to = values
      "Changed #{field.humanize.titleize}: from #{render_changed_value(field, from)} to #{render_changed_value(field, to)}."
    end.compact
  end

  def render_changed_value(field, value)
    return 'NULL' if value.nil?

    field.in?(VISIBLE_FIELDS_VALUES) ? "\"#{value}\"" : '<redacted>'
  end
end
