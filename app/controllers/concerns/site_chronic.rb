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
      GrdaWarehouse::Config.get(:chronic_definition).to_sym
    end

    def site_chronics
      case site_chronic_definition
        when :chronic
          chronics
        when :hud_chronic
          hud_chronics
        else
          raise NotImplementedError
      end
    end

    def site_chronics_sym
      case site_chronic_definition
        when :chronic
          :chronics
        when :hud_chronic
          :hud_chronics
        else
          raise NotImplementedError
      end
    end

    def site_chronics_where(arg)
      case site_chronic_definition
        when :chronic
          {chronics: arg}
        when :hud_chronic
          {hud_chronics: arg}
        else
          raise NotImplementedError
      end
    end

    def site_chronics_in_range(range)
      case site_chronic_definition
        when :chronic
          chronics_in_range(range)
        when :hud_chronic
          hud_chronics_in_range(range)
        else
          raise NotImplementedError
      end
    end

    def site_chronic_source
      case site_chronic_definition
        when :chronic
          potentially_chronic_source
        when :hud_chronic
          hud_chronic_source
        else
          raise NotImplementedError
      end
    end
    # alias_method :chronic_source, :site_chronic_source

    def site_service_history_source
      case site_chronic_definition
        when :chronic
          chronic_service_history_source
        when :hud_chronic
          hud_chronic_service_history_source
        else
          raise NotImplementedError
      end
    end
    # alias_method :service_history_source, :site_service_history_source

    def site_load_chronic_filter
      case site_chronic_definition
        when :chronic
          load_chronic_filter
        when :hud_chronic
          load_hud_chronic_filter
        else
          raise NotImplementedError
      end
    end
    # alias_method :load_filter, :site_load_chronic_filter

    def site_set_chronic_sort
      case site_chronic_definition
        when :chronic
          set_chronic_sort
        when :hud_chronic
          set_hud_chronic_sort
        else
          raise NotImplementedError
      end
    end
    # alias_method :set_sort, :site_set_chronic_sort
  end
end