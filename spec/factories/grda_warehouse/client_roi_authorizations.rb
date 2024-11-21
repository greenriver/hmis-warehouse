FactoryBot.define do
  factory :client_roi_authorization, class: 'GrdaWarehouse::ClientRoiAuthorization' do
    association :destination_client, factory: :grda_warehouse_hud_client
    status { 'full' }
  end
end
