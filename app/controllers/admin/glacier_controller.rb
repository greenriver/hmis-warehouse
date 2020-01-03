###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Admin
  class GlacierController < ApplicationController
    # Stand in permission
    before_action :require_can_add_administrative_event!

    def index
      @vaults = Glacier::Vault.all.index_by(&:id)
      @total_size = Glacier::Archive.sum(:size_in_bytes)
      @archives = Glacier::Archive.all.order(upload_started_at: :desc, upload_finished_at: :desc).
        page(params[:page]).per(50)
    end
  end
end
