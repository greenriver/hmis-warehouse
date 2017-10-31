module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    before_action :require_can_manage_client_files!
    
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
          visible_in_window: file_params[:visible_in_window],
          note: file_params[:note],
          name: file_params[:name],
        )
        tag_list = file_params[:tag_list].select(&:present?)
        @file.tag_list.add(tag_list)
        @file.save!

        # Send notifications if appropriates
        tag_list = ActsAsTaggableOn::Tag.where(name: tag_list).pluck(:id)
        notification_triggers = GrdaWarehouse::Config.get(:file_notifications).pluck(:id)
        to_send = tag_list & notification_triggers
        FileNotificationMailer.notify(to_send, @client.id).deliver_later if to_send.any?

        # Keep various client fields in sync with files if appropriate
        @client.sync_cas_attributes_with_files
      rescue Exception => e
        flash[:error] = e.message
        render action: :new
        return
      end
      redirect_to action: :index 
    end
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
    
    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end
  end
end
