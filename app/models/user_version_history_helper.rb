###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UserVersionHistoryHelper
  # all user cols except sensitive fields, such as credentials
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

  SKIP_RGX = /\A(id|updated_at|created_at)\z/

  def describe_changes(version, changes)
    change_summary(version, changes) || change_details(changes)
  end

  protected

  def change_details(changes)
    changes.map do |field, values|
      next if field =~ /\A(id|updated_at|created_at)\z/

      from, to = values
      "Changed #{field.humanize.titleize}: from #{render_value(field, from)} to #{render_value(field, to)}."
    end.compact
  end

  def change_summary(_version, changes)
    case changes.map(&:first).sort
    # no need to summary logins, we don't show those
    when [
      'encrypted_password',
      'last_activity_at',
      'password_changed_at',
      'updated_at',
    ]
      ['Password Reset']
    when [
      'reset_password_sent_at',
      'reset_password_token',
      'updated_at',
    ]
      ['Password Reset Request']
    end
  end

  def render_value(field, value)
    return 'NULL' if value.nil?

    field.in?(VISIBLE_FIELDS_VALUES) ? value.to_s : '<redacted>'
  end
end
