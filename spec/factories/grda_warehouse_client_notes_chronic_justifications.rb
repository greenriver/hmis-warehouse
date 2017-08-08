FactoryGirl.define do
  factory :grda_warehouse_client_notes_chronic_justification, class: 'GrdaWarehouse::ClientNotes::ChronicJustification' do
    client_id '456'
    user_id '8' 
    note 'Test'
    # type 'GrdaWarehouse::ClientNotes::ChronicJustification'
    # created_at Date.current
    # updated_at
    # deleted_at
  end
end
