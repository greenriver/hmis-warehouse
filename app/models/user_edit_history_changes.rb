###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UserEditHistoryChanges
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

  # Define a constant to hold all the change summary rules.
  # Each rule specifies:
  # - A set of keys to match against the change keys.
  # - A lambda function to compute the summary if the keys match.
  #
  # Note, no need to include a condition for logins, those events are excluded from history
  CHANGE_SUMMARY_RULES = [
    {
      keys: ['active', 'updated_at'].to_set,
      summary: ->(version, changeset) {
        return nil if version.anonymous?
        case changeset['active']
        when [true, false] then 'Account deactivated'
        when [false, true] then 'Account activated'
        end
      }
    },
    {
      keys: ['confirmed_at', 'encrypted_password', 'invitation_accepted_at', 'invitation_token', 'password_changed_at', 'updated_at'].to_set,
      summary: ->(version, _changeset) { version.anonymous? ? 'Invitation accepted' : nil }
    },
    {
      keys: ['encrypted_password', 'last_activity_at', 'password_changed_at', 'updated_at'].to_set,
      summary: ->(version, _changeset) { version.anonymous? ? nil : 'Account activated' }
    },
    {
      keys: ['reset_password_sent_at', 'reset_password_token', 'updated_at'].to_set,
      summary: ->(_version, _changeset) { 'Password Reset Email Sent' }
    },
    {
      keys: ['encrypted_password', 'password_changed_at', 'reset_password_sent_at', 'reset_password_token', 'updated_at'].to_set,
      summary: ->(version, _changeset) { version.anonymous? ? 'Password Reset' : nil }
    }
  ].freeze

  def perform(version, changeset)
    Array.wrap(summary(version, changeset) || details(changeset)).presence
  end

  protected

  # try to concisely summarize common events
  def summary(version, changeset)
    changes = changeset
    case version.event
    when 'create'
      if changeset.dig('invitation_sent_at', 1).present?
        ['Account created', 'Invitation sent']
      else
        'Account created'
      end
    when 'destroy'
      'Account deleted'
    when 'update'
      change_keys = changes.keys.to_set
      matching_rule = CHANGE_SUMMARY_RULES.find { |rule| rule.fetch(:keys) == change_keys }
      matching_rule ? matching_rule.fetch(:summary).call(version, changeset) : nil
    end
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

    field.in?(VISIBLE_FIELDS_VALUES) ? "\"#{value}\"": '<redacted>'
  end
end
