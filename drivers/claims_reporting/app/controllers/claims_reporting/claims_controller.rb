module ClaimsReporting
  class ClaimsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      raise 'TODO'
    end
  end
end
