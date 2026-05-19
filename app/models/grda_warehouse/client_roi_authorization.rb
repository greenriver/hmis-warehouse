###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Currently this is 1:1 with client records; it is automatically generated from canonical ROIs attrs the client
# However in the future we plan to support multiple ROIs and this will likely become the canonical source for ROI
module GrdaWarehouse
  class ClientRoiAuthorization < GrdaWarehouseBase
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client'

    REVOKED_STATUS = 'revoked'
    PARTIAL_STATUS = 'partial'
    FULL_STATUS = 'full'

    scope :with_invalid_client, -> { left_outer_joins(:destination_client).where(c_t[:id].eq(nil)) }
    scope :active, ->(date = Date.current) {
      where(status: [PARTIAL_STATUS, FULL_STATUS]).
        where(arel_table[:starts_at].eq(nil).or(arel_table[:starts_at].lteq(date))).
        where(arel_table[:expires_at].eq(nil).or(arel_table[:expires_at].gteq(date)))
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

      # Mirror valid_in_coc in drivers/client_access_control/extensions/grda_warehouse/hud/client_extension.rb:
      # an ROI that includes "All CoCs" applies to all CoCs and must not require a literal code intersection
      return true if coc_codes.include?('All CoCs')

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
