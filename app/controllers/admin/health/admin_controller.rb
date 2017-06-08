module Admin::Health
  class AdminController < ApplicationController
    before_action :require_can_administer_health!


    def index
      
    end

  end
end