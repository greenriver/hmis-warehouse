module GrdaWarehouse::ClientNotes
  class WindowNote < Base 
    def self.type_name
      "Window Note"
    end

    scope :visible_by, -> (user, client) do
      # If the client has a release and we have permission, show everything
      if client.release_valid? && user.can_edit_window_client_notes?
        current_scope
      else
        # otherwise, only show those we created
        where(user_id: user.id)
      end
    end
  end
end 
