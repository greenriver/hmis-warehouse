###
# Copyright Green River Data Group, Inc.
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

    # Blank coc_codes and 'All CoCs' apply in every CoC
    scope :in_coc_codes, ->(coc_codes) {
      column = arel_table[:coc_codes]
      where(column.eq(nil).or(column.eq([])).or(column.overlaps(Array.wrap(coc_codes) + ['All CoCs'])))
    }

    # The ROI rule for warehouse client visibility; EnrollmentArbiter, ClientRoiLoader and
    # Client#show_demographics_to? must all use it
    scope :visible_in_cocs, ->(coc_codes, date = Date.current) {
      active(date).
        where(status: GrdaWarehouse::Config.active_consent_class.visible_roi_statuses).
        in_coc_codes(coc_codes)
    }

    # An ROI only exposes source clients from data sources that obey consent, so a destination
    # with no such source has nothing to show
    scope :with_consenting_source, -> {
      consenting_destination_ids = GrdaWarehouse::WarehouseClient.
        where(deleted_at: nil).
        joins(source: :data_source).
        merge(GrdaWarehouse::DataSource.obeys_consent).
        select(:destination_id)
      where(destination_client_id: consenting_destination_ids)
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

    def partial_release?
      status == PARTIAL_STATUS
    end

    def full_release?
      status == FULL_STATUS
    end
  end
end
