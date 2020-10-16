module ClaimsReporting
  class HomeController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @patient = Health::Patient.last
    end
  end
end
