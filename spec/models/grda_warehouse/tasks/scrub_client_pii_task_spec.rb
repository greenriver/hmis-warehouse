require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ScrubPii::ScrubClientPiiTask do
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
    create(
      :grda_warehouse_hud_client,
      data_source: data_source,
      FirstName: 'John',
      MiddleName: 'Q',
      LastName: 'Public',
      SSN: '123-45-6789',
      DOB: '1980-01-01',
    )
  end

  let!(:client2) do
    create(
      :grda_warehouse_hud_client,
      data_source: data_source,
      FirstName: 'Jane',
      MiddleName: 'R',
      LastName: 'Doe',
      SSN: '987-65-4321',
      DOB: '1985-02-15',
    )
  end

  # Create enrollments with address data
  let!(:enrollment1) do
    create(
      :grda_warehouse_hud_enrollment,
      data_source: data_source,
      client: client1,
      project: project,
      LastPermanentStreet: '123 Main St',
      LastPermanentCity: 'Boston',
      LastPermanentState: 'MA',
      LastPermanentZIP: '02108',
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
  end

  context 'with defaults' do
    before do
      described_class.new.perform
      reload_records
    end

    it 'nullifies all PII in clients' do
      verify_nullified_client(client1)
      verify_nullified_client(client2)
    end
  end

  context 'with specific client_ids' do
    before do
      described_class.new.perform(client_ids: [client1.id])
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
      create(
        :grda_warehouse_hud_client,
        data_source: other_data_source,
        FirstName: 'Alice',
        LastName: 'Smith'
      )
    end

    before do
      described_class.new.perform(data_source_ids: [data_source.id])
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

  context 'version handling' do
    it 'deletes associated versions' do
      expect do
        described_class.new.perform
      end.to change(GrdaWarehouse::Version, :count).by(-2)
    end
  end

  describe 'custom data element handling' do
    let!(:custom_definition) do
      create(:hmis_custom_data_element_definition, label: 'Client SSN', data_source: data_source)
    end

    let!(:custom_element) do
      create(
        :hmis_custom_data_element,
        owner: client1.as_hmis,
        data_element_definition: custom_definition,
        data_source: data_source,
        value_string: '123-45-6789'
        )
    end

    it 'removes custom elements containing PII' do
      expect do
        described_class.new.perform
      end.to change { Hmis::Hud::CustomDataElement.with_deleted.count }.by(-1)
    end
  end

  describe 'DOB scrambling' do
    it 'maintains age brackets' do
      original_dob = Date.new(1980, 1, 1)
      client1.update(DOB: original_dob)

      described_class.new.perform
      client1.reload

      age_difference_in_years = ((client1.DOB - original_dob) / 365.25).abs
      expect(age_difference_in_years).to be < 5 # Should stay within 5-year bracket
    end
  end

  describe 'custom client record handling' do
    let!(:client_address) do
      create(:hmis_hud_custom_client_address, client: client1.as_hmis, data_source: data_source)
    end
    let!(:client_contact) do
      create(:hmis_hud_custom_client_contact_point, client: client1.as_hmis, data_source: data_source)
    end

    it 'removes all associated custom records' do
      expect do
        described_class.new.perform
      end.to change { Hmis::Hud::CustomClientAddress.with_deleted.count }.by(-1).
        and change { Hmis::Hud::CustomClientContactPoint.with_deleted.count }.by(-1)
    end
  end
end
