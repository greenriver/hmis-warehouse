module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    before_action :require_can_manage_client_files!
    
    def window_visible? visibility
      visibility
    end
    
    def consent_editable?
      can_confirm_housing_release?
    end

    def update
      allowed_params = current_user.can_confirm_housing_release? ? file_params : file_params.except(:consent_form_confirmed)
      attrs = allowed_params
      attrs[:effective_date] = allowed_params[:consent_form_signed_on]
      @file.update(attrs)
    end
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
    
    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end
  end
end
