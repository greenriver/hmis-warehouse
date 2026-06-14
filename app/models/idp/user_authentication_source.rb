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

  # Resolves the managed IDP config (realm + service-account credentials) for this
  # identity's connector, keyed on connector_id rather than denormalizing realm here.
  #
  # NB: this crosses databases — this record is in the app DB, configs live in the
  # warehouse DB. So it loads lazily / via `includes` (separate queries); it CANNOT
  # be used in a SQL `joins`/`eager_load`, and there's no DB-level foreign key.
  # optional: an identity may have no managed config (e.g. ENV-only or OmniAuth IDPs).
  belongs_to :service_config,
             -> { active },
             class_name: 'Idp::ServiceConfig',
             primary_key: :connector_id,
             foreign_key: :connector_id,
             optional: true

  validates :connector_id, presence: true, uniqueness: { scope: [:connector_user_id], conditions: -> { where(deleted_at: nil) } }
  validates :connector_user_id, presence: true
end
