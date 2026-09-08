###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccessLogs::WarehouseReports::UserSummary
  def initialize(range:)
    @range = range
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: 15.minutes) { build }
  end

  private

  def build
    {
      date_range: { start: @range.begin, end: @range.end },
      hmis_enabled: hmis_enabled?,
      access: {
        warehouse: access_rows(ActivityLog.created_in_range(range: @range)),
        hmis: hmis_enabled? ? access_rows(Hmis::ActivityLog.created_in_range(range: @range)) : [],
      },
      created: created_users,
    }
  end

  # One row per user with first and last activity in range. No join to users or access
  # controls: this is an audit of who accessed what, and must include users whose grants
  # were since revoked or who were deleted.
  def access_rows(scope)
    created_at = scope.klass.arel_table[:created_at]
    scope.group(:user_id).
      pluck(:user_id, created_at.minimum, created_at.maximum).
      map { |user_id, first, last| { user_id: user_id, first_access: first, last_access: last } }.
      sort_by { |row| -row[:last_access].to_i }
  end

  def created_users
    users = User.not_system.where(created_at: @range.begin.beginning_of_day..@range.end.end_of_day)
    warehouse_ids = users.warehouse_users.pluck(:id).to_set
    hmis_ids = hmis_enabled? ? users.hmis_users.pluck(:id).to_set : Set.new
    all = users.order(created_at: :desc).pluck(:id, :created_at).map do |id, created_at|
      { user_id: id, created_at: created_at, warehouse: warehouse_ids.include?(id), hmis: hmis_ids.include?(id) }
    end
    { all: all, warehouse_count: warehouse_ids.size, hmis_count: hmis_ids.size }
  end

  def hmis_enabled?
    return @hmis_enabled if defined?(@hmis_enabled)

    @hmis_enabled = HmisEnforcement.hmis_enabled?
  end

  def cache_key
    ['access_logs/user_summary', @range.begin, @range.end]
  end
end
