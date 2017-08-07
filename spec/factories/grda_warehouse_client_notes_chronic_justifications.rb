FactoryGirl.define do
  factory :grda_warehouse_client_notes_chronic_justification, class: 'GrdaWarehouse::ClientNotes::ChronicJustification' do
    client_id '16544'
    user_id '1' 
    note 'Test'
    created_at Date.current
    # updated_at
    # deleted_at
  end
end
