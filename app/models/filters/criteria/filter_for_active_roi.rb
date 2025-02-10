class Filters::Criteria::FilterForActiveRoi < Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.active_roi

  def apply(scope)
    scope.joins(config.join_clients_method).merge(GrdaWarehouse::Hud::Client.consent_form_valid)
  end

end
