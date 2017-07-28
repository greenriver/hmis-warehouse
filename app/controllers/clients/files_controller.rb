module Clients
  class FilesController < ApplicationController
    include ClientPathGenerator
    before_action :require_can_edit_clients!
    before_action :set_client, only: [:index, :show, :new, :create, :edit, :update]
    before_action :set_files, only: [:index]
    before_action :set_file, only: [:show, :edit, :update]
    
    def index
      file_scope.page(params[:page].to_i).per(20).order(created_at: :desc)
    end
    
    def show
      
    end
    
    def new
      @file = file_source.new
    end
    
    def create
      run_import = false
      file = file_params["file"]
      @file = @client.client_files.create(file_params.merge({
        user_id: current_user.id,
        content_type: file.content_type,
        content: file.read,
        }))
      if @file.save
        run_import = true
        flash[:notice] = _("Upload queued to start.")
        redirect_to action: :index
      else
        flash[:alert] = _("Upload failed to queue.")
        render :new
      end
      Importing::RunImportHudZipJob.perform_later(upload: @upload) if run_import
    end
    
    def destroy
      @file = file_source.find(params[:id].to_i)

      begin
        @file.destroy!
        flash[:notice] = "File was successfully deleted."
      rescue Exception => e
        flash[:error] = "File could not be deleted."
      end
      redirect_to files_path(@file.client)
    end
    
    def file_params
      params.require(:grda_warehouse_client_file).
        permit(
          :file,
          :name,
          :note,
        )
    end
    
    def set_client
      @client = client_scope.find(params[:id].to_i)
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
      file_source.where(client_id: @client.id)
    end
  end
end
