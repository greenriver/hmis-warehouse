class Filters::Criteria::FilterForChronicStatus < Filters::Criteria::Base
  def applies? = !config.chronic_at_entry && input.chronic_status

  def apply(scope)
    chronic_source = case GrdaWarehouse::Config.get(:chronic_definition).to_sym
    when :chronics
      GrdaWarehouse::Chronic
    when :hud_chronics
      GrdaWarehouse::HudChronic
    end
    max_date = chronic_source.where(date: input.range).maximum(:date)
    scope.where(client_id: chronic_source.where(date: max_date).select(:client_id))
  end
end
