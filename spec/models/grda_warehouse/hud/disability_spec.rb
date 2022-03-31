require 'rails_helper'

model = GrdaWarehouse::Hud::Disability
RSpec.describe model, type: :model do
  before(:all) do
    import_hmis_csv_fixture(
      'spec/fixtures/files/disabilities',
      version: 'AutoMigrate',
    )
  end
  after(:all) do
    GrdaWarehouse::Utility.clear!
    cleanup_hmis_csv_fixtures
    Delayed::Job.delete_all
  end

  it 'has 3 destination clients' do
    expect(GrdaWarehouse::Hud::Client.destination.count).to eq 3
  end
  it 'has 6 service history enrollments attached to clients' do
    expect(GrdaWarehouse::Hud::Client.destination.joins(:service_history_entries).count).to eq 6
  end
  # 61947 - no based on disabling condition, yes because of disability
  # 61948 - yes based on disabling condition, no because of disability
  # 61949 - no based on disabling condition, no because of disability, but has prior yeses
  {
    '61947' => { disabling_condition: false, disability: true, overall: true },
    '61948' => { disabling_condition: true, disability: false, overall: true },
    '61949' => { disabling_condition: false, disability: false, overall: false },
  }.each do |client_id, conditions|
    describe "When checking client #{client_id}" do
      it "finds disabling condition #{conditions[:disabling_condition]}" do
        client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: client_id).destination_client
        expect(client.class.disabling_condition_client_scope.where(id: client.id).exists?).to be conditions[:disabling_condition]
      end
      it "finds disability #{conditions[:disability]}" do
        client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: client_id).destination_client
        expect(client.class.disabled_client_because_disability_scope.where(id: client.id).exists?).to be conditions[:disability]
      end
      it "finds overall #{conditions[:overall]}" do
        client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: client_id).destination_client
        expect(client.class.disabled_client_scope(client_ids: client.id).where(id: client.id).exists?).to be conditions[:overall]
      end
    end
  end
end
