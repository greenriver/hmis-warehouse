module Admin::Health
  class RolesController < ApplicationController
    before_action :require_can_administer_health!
    
    def index
      @roles = Role.health
    end
  end
end