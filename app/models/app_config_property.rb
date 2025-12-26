###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# generic key value store for db-managed config
# @see docs/features/app-config-property.md
class AppConfigProperty < ApplicationRecord
  before_validation :strip_whitespace

  validates :key, presence: true, uniqueness: true

  private

  def strip_whitespace
    self.key = key&.strip
    self.value = value&.strip
  end
end
