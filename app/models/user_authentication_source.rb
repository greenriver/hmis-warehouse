###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UserAuthenticationSource < ApplicationRecord
  acts_as_paranoid

  belongs_to :user

  validates :connector_id, presence: true, uniqueness: { scope: [:connector_user_id], conditions: -> { where(deleted_at: nil) } }
  validates :connector_user_id, presence: true

  scope :enabled, -> { where(enabled: true) }
end
