###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class InternalSystem < GrdaWarehouseBase
    AUTH_TYPES = [
      OAUTH2  = 'oauth2'.freeze,
      API_KEY = 'apikey'.freeze,
    ].freeze

    NAMES = [
      'Referrals',
      # 'Involvement',
    ].freeze

    validates :active, inclusion: { in: [true, false], message: 'must be set' }
    validates :auth_type, inclusion: { in: AUTH_TYPES, message: "must be in the set #{AUTH_TYPES.join(', ')}" }

    scope :active, -> { where(active: true) }
  end
end
