###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccessLogs::WarehouseReports::UserSummary
  # Bump whenever the shape of the returned hash changes, so cached summaries built by older code
  # are not served to a renderer expecting the new keys.
  CACHE_VERSION = 2

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
      cas_enabled: cas_enabled?,
      access: {
        warehouse: access_rows(ActivityLog.created_in_range(range: @range)),
        hmis: hmis_enabled? ? access_rows(Hmis::ActivityLog.created_in_range(range: @range)) : [],
        cas: cas_enabled? ? access_rows(CasAccess::ActivityLog.created_in_range(range: @range)) : [],
      },
      created: created_users,
    }.then { |summary| summary.merge(cas_user_names: cas_user_names(summary)) }
  end

  # One row per user with first and last activity in range. No join to users or access
  # controls: this is an audit of who accessed what, and must include users whose grants
  # were since revoked or who were deleted. CAS rows carry CAS user ids, not warehouse ids.
  def access_rows(scope)
    created_at = scope.klass.arel_table[:created_at]
    scope.group(:user_id).
      pluck(:user_id, created_at.minimum, created_at.maximum).
      map { |user_id, first, last| { user_id: user_id, first_access: first, last_access: last } }.
      sort_by { |row| -row[:last_access].to_i }
  end

  def created_users
    users = User.not_system.where(created_at: timestamp_range)
    warehouse_ids = users.warehouse_users.pluck(:id).to_set
    hmis_ids = hmis_enabled? ? users.hmis_users.pluck(:id).to_set : Set.new
    all = users.order(created_at: :desc).pluck(:id, :created_at).map do |id, created_at|
      { user_id: id, created_at: created_at, warehouse: warehouse_ids.include?(id), hmis: hmis_ids.include?(id) }
    end
    { all: all, warehouse_count: warehouse_ids.size, hmis_count: hmis_ids.size, cas: created_cas_users }
  end

  # CAS accounts live in the CAS database and need no warehouse account, so they are listed
  # separately by CAS user id rather than folded into the warehouse user list.
  def created_cas_users
    return [] unless cas_enabled?

    CasAccess::User.created_in_range(range: @range).order(created_at: :desc).pluck(:id, :created_at).
      map { |id, created_at| { cas_user_id: id, created_at: created_at } }
  end

  # CAS accounts are separate from warehouse accounts, so names are resolved here rather than by
  # the renderer, which only looks up warehouse users.
  def cas_user_names(summary)
    return {} unless cas_enabled?

    ids = summary[:access][:cas].map { |row| row[:user_id] } + summary[:created][:cas].map { |row| row[:cas_user_id] }
    CasAccess::User.name_with_email_by_id(ids.uniq)
  end

  def timestamp_range
    @range.begin.beginning_of_day..@range.end.end_of_day
  end

  def hmis_enabled?
    return @hmis_enabled if defined?(@hmis_enabled)

    @hmis_enabled = HmisEnforcement.hmis_enabled?
  end

  def cas_enabled?
    return @cas_enabled if defined?(@cas_enabled)

    @cas_enabled = GrdaWarehouse::Config.cas_enabled?
  end

  def cache_key
    ['access_logs/user_summary', CACHE_VERSION, @range.begin, @range.end]
  end
end
