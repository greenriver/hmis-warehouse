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

  def hmis?
    scope == 'hmis_user'
  end

  def warehouse?
    scope == 'user'
  end

  def location_description
    description = ''
    description += "#{city}, " if city
    description += "#{region} " if region
    description += country if country
    description
  end
end
