###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Currently this is 1:1 with client records; it is automatically generated from canonical ROIs attrs the client
# However in the future we plan to support multiple ROIs and this will likely become the canonical source for ROI
module GrdaWarehouse
  class ClientRoiAuthorization < GrdaWarehouseBase
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client'

    REVOKED_STATUS = 'revoked'.freeze
    PARTIAL_STATUS = 'partial'.freeze
    FULL_STATUS = 'full'.freeze

    scope :with_invalid_client, -> { left_outer_joins(:destination_client).where(c_t[:id].eq(nil)) }
    scope :active, ->(date: Date.current) {
      expires_at = arel_table[:expires_at]
      starts_at = arel_table[:starts_at]
      where(status: [PARTIAL_STATUS, FULL_STATUS]).
        where(
          expires_at.eq(nil).and(starts_at.eq(nil)).
          or(expires_at.eq(nil).and(starts_at.lteq(date))).
          or(starts_at.eq(nil).and(expires_at.gteq(date))).
          or(starts_at.lteq(date).and(expires_at.gteq(date))),
        )
    }
    scope :matching_coc_codes, ->(coc_codes) {
      where('coc_codes IS NULL OR coc_codes && ARRAY[?]::varchar[]', coc_codes)
    }

    def active?(date: Date.current)
      case status
      when PARTIAL_STATUS, FULL_STATUS
        date_in_valid_range?(date)
      else
        false
      end
    end

    def date_in_valid_range?(date)
      if expires_at && starts_at
        date.between?(starts_at, expires_at)
      elsif expires_at
        date <= expires_at
      elsif starts_at
        date >= starts_at
      else
        true
      end
    end

    def matches_coc_codes?(any_coc_codes)
      # if there are no codes, assume visibility not limited by COC
      return true if coc_codes.blank?

      (any_coc_codes & coc_codes).present?
    end

    def partial_release?
      status == PARTIAL_STATUS
    end

    def full_release?
      status == FULL_STATUS
    end
  end
end
