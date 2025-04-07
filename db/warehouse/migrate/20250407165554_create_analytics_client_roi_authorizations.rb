class CreateAnalyticsClientRoiAuthorizations < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.client_roi_authorizations"
  end
end
