###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients::Youth
  class IntakeController < ApplicationController
    include ClientDependentControllers

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!
    before_action :require_can_delete_youth_intake!

    def destroy
      @client = searchable_client_scope.find(params[:client_id].to_i)
      if @client.present?
        @client.youth_intakes.destroy_all
        @client.case_managements.destroy_all
        @client.direct_financial_assistances.destroy_all
        @client.youth_referrals.destroy_all
        @client.youth_follow_ups.destroy_all
        # TODO: This does not remove the client from the Youth DataSource

        flash[:notice] = "All Youth information for #{@client.name} has been removed."
        redirect_to client_youth_intakes_path(@client)
      else
        not_authorized!
      end
    end
  end
end
