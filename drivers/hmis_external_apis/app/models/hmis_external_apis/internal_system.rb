###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis
  class InternalSystem < GrdaWarehouseBase
    AUTH_TYPES = [
      OAUTH2  = 'oauth2'.freeze,
      API_KEY = 'apikey'.freeze,
    ].freeze

    # Internal systems that external systems can authenticate to with an inbound API key.
    # 'Referrals' was removed with the inbound LINK Referral API; existing rows are left in place
    # but are no longer offered when creating keys.
    NAMES = [
      'Involvements',
    ].freeze

    validates :active, inclusion: { in: [true, false], message: 'must be set' }
    validates :auth_type, inclusion: { in: AUTH_TYPES, message: "must be in the set #{AUTH_TYPES.join(', ')}" }

    scope :active, -> { where(active: true) }
  end
end
