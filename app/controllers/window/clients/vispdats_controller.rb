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
      @file = GrdaWarehouse::ClientFile.new(vispdat_id: @vispdat.id)
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

    def upload_file
      set_vispdat
      @file = GrdaWarehouse::ClientFile.new
      begin
        file = file_params[:file]
        @file.assign_attributes(
          file: file,
          client_id: @client.id,
          user_id: current_user.id,
          content_type: file&.content_type,
          content: file&.read,
          visible_in_window: file_params[:visible_in_window],
          note: file_params[:note],
          name: file_params[:name],
          vispdat_id: @vispdat.id
        )
        # @file.tag_list.add(tag_list.select(&:present?))
        # force consent form for now
        @file.tag_list.add ['Consent Form']
        @file.save!
        flash[:notice] = "File #{file_params[:name]} saved."
      rescue Exception => e
        flash[:error] = e.message
      end
      redirect_to action: :edit
    end

    def destroy_file
      set_vispdat
      @file = @vispdat.files.find params[:file_id]
      @file.destroy
      respond_with @vispdat
    end

    protected

      def set_client
        @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
      end

      def set_vispdat
        @vispdat = vispdat_source.find(params[:id].to_i)
      end

      def vispdat_params
        params.require(:grda_warehouse_vispdat).permit(*vispdat_source.allowed_parameters)
      end

      def vispdat_source
        GrdaWarehouse::Vispdat
      end

      def file_params
        params.require(:grda_warehouse_client_file).
          permit(
            :file,
            :name,
            :note,
            :visible_in_window,
            tag_list: [],
          )
      end

      def tag_list
        file_params[:tag_list] || []
      end
  end
end
