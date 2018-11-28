module Admin
  class GlacierController < ApplicationController
    # Stand in permission
    before_action :require_can_add_administrative_event!

    def index
      @vaults = Glacier::Vault.all
      @archives = Glacier::Archive.all.order(upload_finished_at: :desc).group_by(&:glacier_vault_id)
    end

  end
end
