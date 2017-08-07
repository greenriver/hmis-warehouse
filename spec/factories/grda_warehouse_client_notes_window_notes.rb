FactoryGirl.define do
  factory :grda_warehouse_client_notes_window_note, class: 'GrdaWarehouse::ClientNotes::WindowNote' do
    client_id '16544'
    user_id '1' 
    note 'Test'
    created_at Date.current
    # updated_at
    # deleted_at
  end
end
