module Window::Clients
  class VispdatsController < ApplicationController
    include WindowClientPathGenerator

    before_action :require_can_view_vspdat!, only: [:index, :show]
    before_action :require_can_edit_vspdat!, only: [:new, :create, :edit, :update, :destroy]

    before_action :set_client
    before_action :set_vispdat, only: [:show, :edit, :update, :destroy]

    def index
      @vispdats = @client.vispdats.order(created_at: :desc)
      respond_with(@vispdats)
    end

    def show
      respond_with(@vispdat)
    end

    # def new
    #   @vispdat = @client.vispdats.build
    #   @vispdat.save(validate: false)
    #   respond_with(@vispdat, action: :edit)
    # end

    def edit
    end

    def create
      if @client.vispdats.in_progress.none?
        @vispdat = @client.vispdats.build
        @vispdat.save(validate: false)
      else
        @vispdat = @client.vispdats.in_progress.first
      end
      respond_with(@vispdat, location: polymorphic_path([:edit] + vispdat_path_generator, client_id: @client.id, id: @vispdat.id))
    end

    def update
      if params[:commit]=='Complete'
        @vispdat.update(vispdat_params.merge(submitted_at: Time.now))
      else
        @vispdat.assign_attributes(vispdat_params)
        @vispdat.save(validate: false)
      end
      respond_with(@vispdat, location: polymorphic_path(vispdats_path_generator, client_id: @client.id))
    end

    protected

      def set_client
        @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id])
      end

      def set_vispdat
        @vispdat = vispdat_source.find(params[:id])
      end

      def vispdat_params
        params.require(:grda_warehouse_vispdat).permit(*vispdat_source.allowed_parameters)
      end

      def vispdat_source
        GrdaWarehouse::Vispdat
      end
  end
end
