###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class LoginActivity < ApplicationRecord
  belongs_to :user, polymorphic: true, optional: true

  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }

  scope :warehouse_logins, -> { where(scope: :user) }
  scope :hmis_logins, -> { where(scope: :hmis_user) }

  def location_description
    description = ''
    description += "#{city}, " if city
    description += "#{region} " if region
    description += country if country
    description
  end

  # Class method to preload the most recent successful Warehouse login for each user.
  # Uses caching to avoid N+1 in reports.
  def self.latest_warehouse_logins
    Rails.cache.fetch('latest_warehouse_logins', expires_in: 1.minute) do
      LoginActivity.successful.warehouse_logins.
        select('DISTINCT ON (user_id) user_id, created_at').
        order(:user_id, created_at: :desc).
        map { |r| [r.user_id, r.created_at] }.to_h
    end
  end

  # Class method to preload the most recent successful HMIS login for each user.
  # Uses caching to avoid N+1 in reports.
  def self.latest_hmis_logins
    Rails.cache.fetch('latest_hmis_logins', expires_in: 1.minute) do
      LoginActivity.successful.hmis_logins.
        select('DISTINCT ON (user_id) user_id, created_at').
        order(:user_id, created_at: :desc).
        map { |r| [r.user_id, r.created_at] }.to_h
    end
  end
end
