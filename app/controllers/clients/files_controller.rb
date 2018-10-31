module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    before_action :require_can_manage_client_files!
    after_action :log_client

    def window_visible? visibility
      visibility
    end

    def consent_editable?
      can_confirm_housing_release?
    end

    def update
      attrs = if current_user.can_confirm_housing_release?
        file_params
      else
        file_params.except(:consent_form_confirmed)
      end

      if attrs.key?(:consent_form_signed_on)
        attrs[:effective_date] = attrs[:consent_form_signed_on]
      end
      @file.update(attrs)
    end

    def all_file_scope
      file_source.where(client_id: @client.id)
    end

    def file_scope
      file_source.non_consent.where(client_id: @client.id)
    end

    def consent_scope
      file_source.consent_forms.where(client_id: @client.id).
        order(consent_form_confirmed: :desc, consent_form_signed_on: :desc)
    end

    def set_window
      @window = false
    end

    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end

    def editable_scope
      file_source.where(client_id: @client.id).
        editable_by?(current_user)
    end
  end
end
