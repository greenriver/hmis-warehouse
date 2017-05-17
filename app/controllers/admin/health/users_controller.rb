module Admin::Health
  class UsersController < ApplicationController
    before_action :require_can_administer_health!
    
    def index
      @users = User.all
    end
  end
end