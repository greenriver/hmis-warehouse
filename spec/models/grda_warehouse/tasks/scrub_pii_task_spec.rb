require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ScrubPii::ScrubPiiTask do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source, project_type: 0 }

  before(:all) do
    PaperTrail.enabled = true
  end
  after(:all) do
    PaperTrail.enabled = false
  end

  # Create test clients with PII
  let!(:client1) do
    create(:grda_warehouse_hud_client,
      data_source: data_source,
      FirstName: 'John',
      MiddleName: 'Q',
      LastName: 'Public',
      SSN: '123-45-6789',
      DOB: '1980-01-01'
    )
  end

  let!(:client2) do
    create(:grda_warehouse_hud_client,
      data_source: data_source,
      FirstName: 'Jane',
      MiddleName: 'R',
      LastName: 'Doe',
      SSN: '987-65-4321',
      DOB: '1985-02-15'
    )
  end

  # Create enrollments with address data
  let!(:enrollment1) do
    create(:grda_warehouse_hud_enrollment,
      data_source: data_source,
      client: client1,
      project: project,
      LastPermanentStreet: '123 Main St',
      LastPermanentCity: 'Boston',
      LastPermanentState: 'MA',
      LastPermanentZIP: '02108'
    )
  end

  # Helper methods
  def reload_records
    client1.reload
    client2.reload
    enrollment1.reload
  end

  def verify_nullified_client(client)
    expect(client.FirstName).to be_nil
    expect(client.MiddleName).to be_nil
    expect(client.LastName).to be_nil
    expect(client.SSN).to be_nil
    expect(client.NameDataQuality).to eq(99)
    expect(client.SSNDataQuality).to eq(99)
  end

  def verify_nullified_enrollment(enrollment)
    expect(enrollment.LastPermanentStreet).to be_nil
    expect(enrollment.LastPermanentCity).to be_nil
    expect(enrollment.LastPermanentState).to be_nil
    expect(enrollment.LastPermanentZIP).to be_nil
    expect(enrollment.AddressDataQuality).to eq(99)
  end

  describe '#perform' do
    context 'with null strategy' do
      before do
        described_class.new.perform(strategy: :null)
        reload_records
      end

      it 'nullifies all PII in clients' do
        verify_nullified_client(client1)
        verify_nullified_client(client2)
      end

      it 'nullifies all PII in enrollments' do
        verify_nullified_enrollment(enrollment1)
      end

      it 'maintains non-PII data' do
        expect(client1.PersonalID).not_to be_nil
        expect(enrollment1.ProjectID).not_to be_nil
      end
    end

    context 'with fake strategy' do
      before do
        described_class.new.perform(strategy: :fake)
        reload_records
      end

      it 'replaces client PII with fake data' do
        expect(client1.FirstName).not_to eq('John')
        expect(client1.FirstName).not_to be_nil
        expect(client1.LastName).not_to eq('Public')
        expect(client1.LastName).not_to be_nil
        expect(client1.SSN).not_to eq('123-45-6789')
        expect(client1.SSN).not_to be_nil
      end

      it 'replaces enrollment PII with fake data' do
        expect(enrollment1.LastPermanentStreet).not_to eq('123 Main St')
        expect(enrollment1.LastPermanentStreet).not_to be_nil
        expect(enrollment1.LastPermanentCity).not_to eq('Boston')
        expect(enrollment1.LastPermanentCity).not_to be_nil
      end
    end

    context 'with identifier strategy' do
      before do
        described_class.new.perform(strategy: :identifier)
        reload_records
      end

      it 'replaces PII with identifier-based values' do
        expect(client1.FirstName).to eq("FirstName#{client1.id}")
        expect(client1.LastName).to eq("LastName#{client1.id}")
      end

      it 'replaces enrollment data with identifier-based values' do
        expect(enrollment1.LastPermanentStreet).to eq("LastPermanentStreet#{enrollment1.id}")
        expect(enrollment1.LastPermanentCity).to eq("LastPermanentCity#{enrollment1.id}")
      end
    end

    context 'with specific client_ids' do
      before do
        described_class.new.perform(
          strategy: :null,
          client_ids: [client1.id]
        )
        reload_records
      end

      it 'only scrubs specified clients' do
        verify_nullified_client(client1)

        expect(client2.FirstName).to eq('Jane')
        expect(client2.LastName).to eq('Doe')
      end
    end

    context 'with specific data_source_ids' do
      let(:other_data_source) { create(:grda_warehouse_data_source) }
      let!(:other_client) do
        create(:grda_warehouse_hud_client,
          data_source: other_data_source,
          FirstName: 'Alice',
          LastName: 'Smith'
        )
      end

      before do
        described_class.new.perform(
          strategy: :null,
          data_source_ids: [data_source.id]
        )
        reload_records
        other_client.reload
      end

      it 'only scrubs clients from specified data sources' do
        verify_nullified_client(client1)
        verify_nullified_client(client2)

        expect(other_client.FirstName).to eq('Alice')
        expect(other_client.LastName).to eq('Smith')
      end
    end

    context 'error handling' do
      it 'raises error for invalid strategy' do
        expect {
          described_class.new.perform(strategy: :invalid)
        }.to raise_error(ArgumentError)
      end
    end

    context 'version handling' do
      it 'deletes associated versions' do
        expect {
          described_class.new.perform(strategy: :null)
        }.to change(GrdaWarehouse::Version, :count).by(-2)
      end
    end
  end
end
