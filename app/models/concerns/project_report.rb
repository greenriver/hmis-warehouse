###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectReport
  extend ActiveSupport::Concern
  include ArelHelper

  included do
    def enrolled_client_counts(start_date:, end_date:)
      enrolled_scope(start_date: start_date, end_date: end_date).select(:client_id).distinct.count
    end

    def enrolled_household_counts(start_date:, end_date:)
      # NB: sometimes household_id is blank; use client id instead.
      enrolled_scope(start_date: start_date, end_date: end_date).select(cl(she_t[:household_id], cast(she_t[:client_id], 'varchar')).to_sql).distinct.count
    end

    def active_client_counts(start_date:, end_date:)
      @active_client_counts ||= active_scope(start_date: start_date, end_date: end_date).select(:client_id).distinct.count
    end

    def entering_clients(start_date:, end_date:)
      entering_scope(start_date: start_date, end_date: end_date).distinct
    end

    def leavers(start_date:, end_date:)
      exiting_scope(start_date: start_date, end_date: end_date).distinct
    end

    def stayers(start_date:, end_date:)
      enrolled_scope(start_date: start_date, end_date: end_date).
        where.not(client_id: leavers(start_date: start_date, end_date: end_date).select(:client_id))
    end

    def housed_between(start_date:, end_date:)
      enrolled_scope(start_date: start_date, end_date: end_date).
        joins(:enrollment).
        merge(
          GrdaWarehouse::Hud::Enrollment.
            where(MoveInDate: (start_date..end_date)),
        )
    end

    def bed_inventory_counts(start_date:, end_date:)
      @bed_inventory_counts ||= inventory_scope(start_date: start_date, end_date: end_date).sum(:BedInventory)
    end

    def average_daily_client_counts(start_date:, end_date:)
      @average_daily_client_counts ||= (services_provided(start_date: start_date, end_date: end_date).count.to_f / day_count(start_date: start_date, end_date: end_date)).round(1)
    end

    def bed_utilization_percent(start_date:, end_date:)
      (average_daily_client_counts(start_date: start_date, end_date: end_date).to_f / bed_inventory_counts(start_date: start_date, end_date: end_date) * 100).round
    rescue StandardError
      'N/A'
    end

    def day_count(start_date:, end_date:)
      (end_date - start_date).to_i
    end

    def services_provided(start_date:, end_date:)
      active_scope(start_date: start_date, end_date: end_date).joins(:service_history_services)
    end

    def inventory_scope(start_date:, end_date:)
      inventories.merge(GrdaWarehouse::Hud::Inventory.within_range(start_date..end_date))
    end

    def entering_scope(start_date:, end_date:)
      enrolled_scope(start_date: start_date, end_date: end_date).
        entry_within_date_range(start_date: start_date, end_date: end_date)
    end

    def exiting_scope(start_date:, end_date:)
      enrolled_scope(start_date: start_date, end_date: end_date).
        exit_within_date_range(start_date: start_date, end_date: end_date)
    end

    def active_scope(start_date:, end_date:)
      enrolled_scope(start_date: start_date, end_date: end_date).
        with_service_between(start_date: start_date, end_date: end_date)
    end

    def enrolled_scope(start_date:, end_date:)
      enrollment_source.in_project(id).
        open_between(start_date: start_date, end_date: end_date)
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end
