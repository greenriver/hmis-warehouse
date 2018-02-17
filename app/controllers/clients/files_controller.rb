module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    before_action :require_can_manage_client_files!
    
    def create
      @file = file_source.new
      begin
        allowed_params = current_user.can_confirm_housing_release? ? file_params : file_params.except(:consent_form_confirmed)
        file = allowed_params[:file]
        @file.assign_attributes(
          file: file,
          client_id: @client.id,
          user_id: current_user.id,
          # content_type: file&.content_type,
          content: file&.read,
          visible_in_window: allowed_params[:visible_in_window],
          note: allowed_params[:note],
          name: allowed_params[:name],
          consent_form_signed_on: allowed_params[:consent_form_signed_on],
          consent_form_confirmed: allowed_params[:consent_form_confirmed],
        )
        tag_list = allowed_params[:tag_list].select(&:present?)
        @file.tag_list.add(tag_list)
        @file.save!

        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
      rescue Exception => e
        flash[:error] = e.message
        render action: :new
        return
      end
      redirect_to action: :index 
    end

    def update
      allowed_params = current_user.can_confirm_housing_release? ? file_params : file_params.except(:consent_form_confirmed)
      @file.update(allowed_params)
    end
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
    
    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end
  end
end
