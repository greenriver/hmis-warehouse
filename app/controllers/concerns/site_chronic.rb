###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#
# SiteChronic is a wrapper around the Chronic and HudChronic concerns that selects the appropriate chronic definition
# based on the site configuration.
#
module SiteChronic
  extend ActiveSupport::Concern
  include Chronic
  include HudChronic

  included do
    def site_chronic_definition
      @site_chronic_definition ||= GrdaWarehouse::Config.get(:chronic_definition).to_sym
    end
    alias_method :site_chronics_table, :site_chronic_definition

    def site_chronics
      send(site_chronic_definition)
    end

    def site_chronics_in_range(range)
      case site_chronic_definition
      when :chronics
        chronics_in_range(range)
      when :hud_chronics
        hud_chronics_in_range(range)
      else
        raise NotImplementedError
      end
    end

    def site_chronic_source
      case site_chronic_definition
      when :chronics
        potentially_chronic_source
      when :hud_chronics
        hud_chronic_source
      else
        raise NotImplementedError
      end
    end
    # alias_method :chronic_source, :site_chronic_source

    def site_service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def site_load_chronic_filter
      case site_chronic_definition
      when :chronics
        load_chronic_filter
      when :hud_chronics
        load_hud_chronic_filter
      else
        raise NotImplementedError
      end
    end
    # alias_method :load_filter, :site_load_chronic_filter

    def site_set_chronic_sort
      case site_chronic_definition
      when :chronics
        set_chronic_sort
      when :hud_chronics
        set_hud_chronic_sort
      else
        raise NotImplementedError
      end
    end
    # alias_method :set_sort, :site_set_chronic_sort
  end
end
