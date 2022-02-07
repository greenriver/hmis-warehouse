###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::ClientConcern
  extend ActiveSupport::Concern
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  included do
    include ArelHelper
    protected def set_client
      # Do we have this client?
      # If we don't, attempt to redirect to the most recent version
      # If there's not merge path, just force an active record not found
      # This query is slow, even as an exists query, so just attempt to load the client
      id = params[:id].to_i
      @client = client_scope(id: id).find_by(id: id)

      return if @client.present?

      client_id = GrdaWarehouse::ClientMergeHistory.new.current_destination(id)
      if client_id
        redirect_to controller: controller_name, action: action_name, id: client_id
        return
      end

      # Throw a 404 by looking for a non-existent client
      # Using 0 here against the client model will be *much* faster than trying the search again
      @client = client_source.find(0)
    end
  end
end
