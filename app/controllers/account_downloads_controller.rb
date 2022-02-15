###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccountDownloadsController < ApplicationController
  before_action :set_user

  def index
    limit = 50
    @items = @user.document_exports.diet_select.
      completed.limit(limit).order(created_at: :desc).to_a
    @items += @user.health_document_exports.diet_select.
      completed.limit(limit).order(created_at: :desc).to_a
    @items = @items.sort_by { |e| e.created_at.to_i * -1 }
  end

  private def set_user
    @user = current_user
  end
end
