module SiteChronic
  extend ActiveSupport::Concern
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
          GrdaWarehouse::Chronic
        when :hud_chronic
          GrdaWarehouse::HudChronic
        else
          raise NotImplementedError
      end
    end
  end
end