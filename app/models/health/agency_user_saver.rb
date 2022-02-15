###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class AgencyUserSaver

    include ActiveModel::Model

    attr_accessor :user_id, :agency_ids, :user, :agencies

    def initialize(params={})
      @user_id = params[:user_id]
      @agency_ids = params[:agency_ids]
      @user = User.find(@user_id)
      @agencies = Health::Agency.where(id: @agency_ids) || []
    end

    def save
      success = true
      begin
        Health::AgencyUser.transaction do
          @user.agency_users.destroy_all
          @agencies.each do |agency|
            Health::AgencyUser.create(user: @user, agency: agency)
          end
        end
      rescue Exception => e
        success = false
      end
      return success
    end

  end
end
