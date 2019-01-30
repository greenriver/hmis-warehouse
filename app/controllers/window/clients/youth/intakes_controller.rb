module Window::Clients::Youth
  class IntakesController < ApplicationController
    include WindowClientPathGenerator

    before_action :require_can_access_youth_intake_list!, only: [:index, :show]

    before_action :set_client
    after_action :log_client

    def index
      # @intakes = @client.youth_intakes.merge(GrdaWarehouse::YouthIntake::Base.visible_by?(current_user))
    end

    def set_client
      @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
    end

  end
end