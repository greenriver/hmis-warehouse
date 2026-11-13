###
# Copyright Green River Data Group, Inc.
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
  # Both tables live in the app DB, so this supports `joins`/`eager_load`. The key is
  # connector_id (not the PK) and isn't uniquely constrained on its own, so there's no
  # DB-level foreign key. optional: an identity may have no managed config (e.g.
  # ENV-only or OmniAuth IDPs).
  belongs_to :service_config,
             -> { active },
             class_name: 'Idp::ServiceConfig',
             primary_key: :connector_id,
             foreign_key: :connector_id,
             optional: true

  validates :connector_id, presence: true, uniqueness: { scope: [:connector_user_id], conditions: -> { where(deleted_at: nil) } }
  validates :connector_user_id, presence: true
end
