###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceHistoryServiceConcern
  extend ActiveSupport::Concern
  included do
    scope :service, -> { where record_type: service_types }
    scope :extrapolated, -> { where record_type: :extrapolated }
    # The following scope is sometimes used to determine if any "real" service
    # was performed within a date range, it isn't correctly interpreted
    # if used with ServiceHistoryEnrollment.with_service_between
    # unless it is explicitly a string
    scope :service_excluding_extrapolated, -> { where(record_type: :service) }

    scope :residential, -> {
      where(project_type_column => GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
    }

    scope :hud_residential, -> do
      hud_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
    end

    scope :residential_non_homeless, -> do
      r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
      where(project_type_column => r_non_homeless).where(homeless: false)
    end
    scope :hud_residential_non_homeless, -> do
      r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
      hud_project_type(r_non_homeless).where(homeless: false)
    end

    scope :literally_homeless, -> do
      where(arel_table[:literally_homeless].eq(true))
    end

    scope :homeless, ->(chronic_types_only: false) do
      if chronic_types_only
        where(arel_table[:literally_homeless].eq(true))
      else
        where(arel_table[:homeless].eq(true))
      end
    end

    scope :non_literally_homeless, -> do
      where(arel_table[:literally_homeless].eq(false))
    end

    scope :non_homeless, -> do
      where(arel_table[:homeless].eq(false))
    end

    scope :hud_homeless, ->(chronic_types_only: true) do # rubocop:disable Lint/UnusedBlockArgument
      homeless(chronic_types_only: true)
    end

    scope :in_project_type, ->(project_types) do
      where(project_type_column => project_types)
    end

    scope :service_within_date_range, ->(start_date:, end_date:) do
      at = arel_table
      service.where(at[:date].gteq(start_date).and(at[:date].lteq(end_date)))
    end

    scope :service_in_last_three_years, -> {
      service_in_prior_years(years: 3)
    }

    scope :service_in_prior_years, ->(years: 3) do
      service_within_date_range(start_date: years.years.ago.to_date, end_date: Date.current)
    end

    scope :bed_night, -> do
      where(service_type: 200)
    end

    def self.service_types
      service_types = ['service']
      service_types << 'extrapolated' if GrdaWarehouse::Config.get(:so_day_as_month)
      service_types
    end
  end
end
