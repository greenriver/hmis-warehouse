module Window::Clients
  class FilesController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_window_file_access!
    before_action :set_client, only: [:index, :show, :new, :create, :edit, :update]
    before_action :set_files, only: [:index]
    before_action :set_file, only: [:show, :edit, :update]
    
    def index
      @consent_form_url = GrdaWarehouse::Config.get(:url_of_blank_consent_form)
      @files = file_scope.page(params[:page].to_i).per(20).order(created_at: :desc)
    end
    
    def show
      download
    end
    
    def new
      @file = file_source.new
    end
    
    def create
      @file = file_source.new
      begin
        file = file_params[:file]
        @file.assign_attributes(
          file: file,
          client_id: @client.id,
          user_id: current_user.id,
          content_type: file&.content_type,
          content: file&.read,
          visible_in_window: true,
          note: file_params[:note],
          name: file_params[:name],
          consent_form_signed_on: file_params[:consent_form_signed_on],
          consent_form_confirmed: file_params[:consent_form_confirmed]
        )
        tag_list = file_params[:tag_list].select(&:present?)
        @file.tag_list.add(tag_list)
        @file.save!

        # Keep various client fields in sync with files if appropriate
        @file.client.sync_cas_attributes_with_files

      rescue Exception => e
        flash[:error] = e.message
        render action: :new
        return
      end
      redirect_to action: :index 
    end
    
    def destroy
      @file = file_source.find(params[:id].to_i)
      @client = @file.client
      
      begin
        @file.destroy!
        flash[:notice] = "File was successfully deleted."
        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
      rescue Exception => e
        flash[:error] = "File could not be deleted."
      end
      redirect_to polymorphic_path(files_path_generator, client_id: @client.id)
    end
    
    def download 
      send_data(@file.content, type: @file.content_type, filename: File.basename(@file.file.to_s))
    end
    
    def file_params
      params.require(:grda_warehouse_client_file).
        permit(
          :file,
          :name,
          :note,
          :visible_in_window,
          :consent_form_signed_on,
          :consent_form_confirmed,
          tag_list: [],
        )
    end
    
    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end
    
    def set_file
      @file = file_scope.find(params[:id].to_i)
    end
    
    def set_files
      @files = file_scope
    end
    
    def client_source
      GrdaWarehouse::Hud::Client
    end
    
    def file_source
      GrdaWarehouse::ClientFile
    end
      
    def client_scope
      client_source.destination
    end
    
    def file_scope
      file_source.window.where(client_id: @client.id).
        visible_by?(current_user)
    end
    
  end
end
