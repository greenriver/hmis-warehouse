# frozen_string_literal: true

class Filters::Criteria::FilterForActiveRoi < Filters::Criteria::Base
  def applies? = input.active_roi

  def apply(scope)
    scope = super(scope)
    scope.joins(config.join_clients_method).merge(GrdaWarehouse::Hud::Client.consent_form_valid)
  end
end
