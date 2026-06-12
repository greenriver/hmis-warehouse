###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Idp::UserAuthenticationSource < ApplicationRecord
  # Namespaced under Idp for code organization, but the table predates the namespace.
  self.table_name = 'user_authentication_sources'

  acts_as_paranoid

  belongs_to :user

  validates :connector_id, presence: true, uniqueness: { scope: [:connector_user_id], conditions: -> { where(deleted_at: nil) } }
  validates :connector_user_id, presence: true
end
