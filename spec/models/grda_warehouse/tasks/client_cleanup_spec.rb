require 'rails_helper'

DEFAULT_DEST_ATTR = {
  FirstName: 'Blair',
  LastName: 'Abbott',
  SSN: '555555555',
  DOB: '1978-06-12',
  VeteranStatus: nil,
  Female: nil,
  Male: nil,
  NoSingleGender: nil,
  Transgender: nil,
  Questioning: nil,
  GenderNone: nil,
}.freeze

RSpec.describe GrdaWarehouse::Tasks::ClientCleanup, type: :model do
  describe 'When Updating destination records from client sources, using db based relationships' do
    GrdaWarehouse::Config.delete_all
    let!(:config) { create(:config) }
    let!(:destination_client) { create(:grda_warehouse_hud_client, PersonalID: 2) }
    let!(:source_data_source) { create(:source_data_source) }
    let!(:source_1) do
      create(
        :grda_warehouse_hud_client,
        PersonalID: 2,
        data_source: source_data_source,
        DateUpdated: 1.day.ago,
        DateCreated: 2.days.ago,
      )
    end
    let!(:source_2) do
      create(
        :grda_warehouse_hud_client,
        PersonalID: 3,
        data_source: source_data_source,
        DateUpdated: 2.day.ago,
        DateCreated: 3.days.ago,
      )
    end

    before(:each) do
      destination_client.update(DEFAULT_DEST_ATTR)
      @dest_attr = destination_client.attributes.with_indifferent_access

      [source_1, source_2].each do |client|
        GrdaWarehouse::WarehouseClient.create(
          id_in_source: client.PersonalID,
          source_id: client.id,
          destination_id: destination_client.id,
          data_source_id: client.data_source_id,
        )
      end
      GrdaWarehouse::WarehouseClientsProcessed.create(client_id: destination_client.id, routine: :service_history)
    end

    before(:all) do
      @dob_1 = Date.new(1978, 6, 12)
      @dob_2 = Date.new(1977, 10, 31)
      @ssn1 = '123456789'
      @ssn2 = '987654321'
      @veteran = 1
      @civilian = 0
      @cleanup = GrdaWarehouse::Tasks::ClientCleanup.new
    end

    it "doesn't select blank names" do
      source_1.update(FirstName: 'Correct', LastName: 'Update', NameDataQuality: 99)
      source_2.update(FirstName: '', LastName: '', NameDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Correct')
      expect(destination_client.LastName).to eq('Update')
    end

    it 'keeps the original name fields if all sources are blank' do
      source_1.update(FirstName: '', LastName: '', NameDataQuality: 99)
      source_2.update(FirstName: '', LastName: '', NameDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Blair')
      expect(destination_client.LastName).to eq('Abbott')
    end

    it 'chooses the first and last name of the highest quality record' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 99)
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Right')
      expect(destination_client.LastName).to eq('Right')
    end

    it 'chooses the first and last name of the highest quality record, even if the quality is nil' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil)
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Right')
      expect(destination_client.LastName).to eq('Right')
    end

    it 'chooses the first and last name of the highest quality record, and treats nil like 99' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil)
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Right')
      expect(destination_client.LastName).to eq('Right')
    end

    it "chooses the oldest record's names when quality is equivalent" do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 9, DateCreated: Date.new(2017, 5, 1))
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9, DateCreated: Date.new(2016, 5, 1))

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Right')
      expect(destination_client.LastName).to eq('Right')
    end

    it "chooses the newest record's names when quality is equivalent and config is set to use latest name" do
      config.update(warehouse_client_name_order: :latest)
      config.invalidate_cache

      source_1.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9, DateCreated: Date.new(2017, 5, 1))
      source_2.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 9, DateCreated: Date.new(2016, 5, 1))

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Right')
      expect(destination_client.LastName).to eq('Right')

      config.update(warehouse_client_name_order: :earliest)
    end

    it 'chooses the oldest, and treats nil like 99' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil, DateCreated: Date.new(2017, 5, 1))
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 99, DateCreated: Date.new(2016, 5, 1))

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.FirstName).to eq('Right')
      expect(destination_client.LastName).to eq('Right')
    end

    it 'sets DOB to nil if all client records are blank' do
      source_1.update(DOB: nil, DOBDataQuality: 99)
      source_2.update(DOB: nil, DOBDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.DOB).to be_nil
    end

    it 'only updates DOB from clients with a value' do
      source_1.update(DOB: @dob_1, DOBDataQuality: 99)
      source_2.update(DOB: nil, DOBDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.DOB).to eq(@dob_1)
    end

    it 'only updates DOB from clients with a value, even if the quality is nil' do
      source_1.update(DOB: @dob_1, DOBDataQuality: nil)
      source_2.update(DOB: nil, DOBDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.DOB).to eq(@dob_1)
    end

    it 'chooses the highest quality DOB' do
      source_1.update(DOB: @dob_1, DOBDataQuality: 99)
      source_2.update(DOB: @dob_2, DOBDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.DOB).to eq(@dob_2)
    end

    it 'chooses the highest quality DOB and treats nil like 99' do
      source_1.update(DOB: @dob_1, DOBDataQuality: nil)
      source_2.update(DOB: @dob_2, DOBDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.DOB).to eq(@dob_2)
    end

    it "chooses the oldest record's DOB when quality is equivalent" do
      source_1.update(DOB: @dob_1, DOBDataQuality: 9, DateCreated: Date.new(2016, 5, 1))
      source_2.update(DOB: @dob_2, DOBDataQuality: 9, DateCreated: Date.new(2017, 5, 1))

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.DOB).to eq(@dob_1)
    end

    it 'sets SSN to nil if all client records are blank' do
      source_1.update(SSN: nil, SSNDataQuality: 99)
      source_2.update(SSN: nil, SSNDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.SSN).to be_nil
    end

    it 'only updates SSN from clients with a value' do
      source_1.update(SSN: @ssn1, SSNDataQuality: 99)
      source_2.update(SSN: nil, SSNDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.SSN).to eq(@ssn1)
    end

    it 'chooses the highest quality SSN' do
      source_1.update(SSN: @ssn1, SSNDataQuality: 99)
      source_2.update(SSN: @ssn2, SSNDataQuality: 9)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.SSN).to eq(@ssn2)
    end

    it "chooses the oldest record's SSN if all have equivalent quality" do
      source_1.update(SSN: @ssn1, SSNDataQuality: 9, DateCreated: Date.new(2017, 5, 1))
      source_2.update(SSN: @ssn2, SSNDataQuality: 9, DateCreated: Date.new(2016, 5, 1))

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.SSN).to eq(@ssn2)
    end

    it 'overwrites nil veteran status if something is non-blank' do
      source_1.update(VeteranStatus: nil, DateUpdated: 3.days.ago)
      source_2.update(VeteranStatus: 99, DateUpdated: 2.days.ago)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.VeteranStatus).to eq(99)
    end

    it 'maintains the newest veteran status if there is no yes' do
      destination_client.update(VeteranStatus: @veteran)
      source_1.update(VeteranStatus: 99, DateUpdated: 3.days.ago)
      source_2.update(VeteranStatus: 8, DateUpdated: 2.days.ago)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.VeteranStatus).to eq(8)
    end

    it 'sets to no when override is set, even if newer answer is yes' do
      destination_client.update(VeteranStatus: @veteran, verified_veteran_status: :non_veteran)
      source_1.update(VeteranStatus: 99, DateUpdated: 3.days.ago)
      source_2.update(VeteranStatus: @veteran, DateUpdated: 2.days.ago)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.VeteranStatus).to eq(@civilian)
    end

    it 'maintains veteran status of yes, even when no is newer' do
      destination_client.update(VeteranStatus: @veteran)
      source_1.update(VeteranStatus: @civilian, DateUpdated: 1.day.ago)
      source_2.update(VeteranStatus: @veteran, DateUpdated: 2.days.ago)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.VeteranStatus).to eq(@veteran)
    end

    it 'updates veteran status with the newest yes/no value' do
      destination_client.update(VeteranStatus: @veteran)
      source_1.update(VeteranStatus: @civilian, DateUpdated: 2.days.ago)
      source_2.update(VeteranStatus: @veteran, DateUpdated: 1.days.ago)

      @cleanup.update_client_demographics_based_on_sources
      destination_client.reload
      expect(destination_client.VeteranStatus).to eq(@veteran)
    end

    describe 'Gender Fields' do
      (::HUD.gender_fields - [:GenderNone]).each do |col|
        it "uses newest known gender value for #{col}" do
          destination_client.update(col => 1)
          source_1.update(col => 1, DateUpdated: 2.days.ago)
          source_2.update(col => 0, DateUpdated: 1.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end

        it 'overwrites nil gender if something is non-blank' do
          source_1.update(col => nil, DateUpdated: 3.days.ago)
          source_2.update(col => 99, DateUpdated: 2.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(99)
        end

        it 'only updates gender known value if some client is a known value' do
          destination_client.update(col => 0)
          destination_client.reload
          source_1.update(col => 99, DateUpdated: 3.days.ago) # while valid, it should not change the 0
          source_2.update(col => 8, DateUpdated: 2.days.ago) # note, this is an invalid value
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end

        it 'overwrites gender with newest known value' do
          destination_client.update(col => 0)
          source_1.update(col => 1, DateUpdated: 1.day.ago)
          source_2.update(col => 0, DateUpdated: 2.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(1)
        end

        it 'uses newest known gender value' do
          destination_client.update(col => 1)
          source_1.update(col => 1, DateUpdated: 2.days.ago)
          source_2.update(col => 0, DateUpdated: 1.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end
      end
    end

    describe 'Race Fields' do
      (GrdaWarehouse::Hud::Client.race_fields.map(&:to_sym) - [:RaceNone]).each do |col|
        it "uses newest known race value for #{col}" do
          destination_client.update(col => 1)
          source_1.update(col => 1, DateUpdated: 2.days.ago)
          source_2.update(col => 0, DateUpdated: 1.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end

        it 'overwrites nil race if something is non-blank' do
          source_1.update(col => nil, DateUpdated: 3.days.ago)
          source_2.update(col => 99, DateUpdated: 2.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(99)
        end

        it 'only updates race known value if some client is a known value' do
          destination_client.update(col => 0)
          destination_client.reload
          source_1.update(col => 99, DateUpdated: 3.days.ago) # while valid, it should not change the 0
          source_2.update(col => 8, DateUpdated: 2.days.ago) # note, this is an invalid value
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end

        it 'overwrites race with newest known value' do
          destination_client.update(col => 0)
          source_1.update(col => 1, DateUpdated: 1.day.ago)
          source_2.update(col => 0, DateUpdated: 2.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(1)
        end

        it 'uses newest known race value' do
          destination_client.update(col => 1)
          source_1.update(col => 1, DateUpdated: 2.days.ago)
          source_2.update(col => 0, DateUpdated: 1.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end
      end
    end
    describe 'Ethnicity' do
      [:Ethnicity].each do |col|
        it "uses newest known value for #{col}" do
          destination_client.update(col => 1)
          source_1.update(col => 1, DateUpdated: 2.days.ago)
          source_2.update(col => 0, DateUpdated: 1.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end

        it "overwrites nil #{col} if something is non-blank" do
          source_1.update(col => nil, DateUpdated: 3.days.ago)
          source_2.update(col => 99, DateUpdated: 2.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(99)
        end

        it "only updates #{col} known value if some client is a known value" do
          destination_client.update(col => 0)
          destination_client.reload
          source_1.update(col => 99, DateUpdated: 3.days.ago) # while valid, it should not change the 0
          source_2.update(col => 8, DateUpdated: 2.days.ago) # note, this is an invalid value
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end

        it "overwrites #{col} with newest known value" do
          destination_client.update(col => 0)
          source_1.update(col => 1, DateUpdated: 1.day.ago)
          source_2.update(col => 0, DateUpdated: 2.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(1)
        end

        it "uses newest known #{col} value" do
          destination_client.update(col => 1)
          source_1.update(col => 1, DateUpdated: 2.days.ago)
          source_2.update(col => 0, DateUpdated: 1.days.ago)
          @cleanup.update_client_demographics_based_on_sources
          destination_client.reload
          expect(destination_client[col]).to eq(0)
        end
      end
    end
  end
  describe 'When Updating destination records from client sources' do
    let!(:destination_client) { create(:grda_warehouse_hud_client) }
    let!(:source_1) { create(:grda_warehouse_hud_client) }
    let!(:source_2) { create(:grda_warehouse_hud_client) }

    before(:each) do
      destination_client.update(DEFAULT_DEST_ATTR)
      @dest_attr = destination_client.attributes.with_indifferent_access
    end

    before(:all) do
      @dob_1 = Date.new(1978, 6, 12)
      @dob_2 = Date.new(1977, 10, 31)
      @ssn1 = '123456789'
      @ssn2 = '987654321'
      @veteran = 1
      @civilian = 0
      @cleanup = GrdaWarehouse::Tasks::ClientCleanup.new
    end

    it "doesn't select blank names" do
      source_1.update(FirstName: 'Correct', LastName: 'Update', NameDataQuality: 99)
      source_2.update(FirstName: '', LastName: '', NameDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:FirstName]).to eq('Correct')
      expect(@dest_attr[:LastName]).to eq('Update')
    end

    it 'keeps the original name fields if all sources are blank' do
      source_1.update(FirstName: '', LastName: '', NameDataQuality: 99)
      source_2.update(FirstName: '', LastName: '', NameDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end
      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:FirstName]).to eq('Blair')
      expect(@dest_attr[:LastName]).to eq('Abbott')
    end

    it 'chooses the first and last name of the highest quality record' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 99)
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it 'chooses the first and last name of the highest quality record, even if the quality is nil' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil)
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it 'chooses the first and last name of the highest quality record, and treats nil like 99' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil)
      source_2.update!(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end
      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "chooses the oldest record's names when quality is equivalent" do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 9, DateCreated: Date.new(2017, 5, 1))
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 9, DateCreated: Date.new(2016, 5, 1))
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it 'chooses the oldest, and treats nil like 99' do
      source_1.update(FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil, DateCreated: Date.new(2017, 5, 1))
      source_2.update(FirstName: 'Right', LastName: 'Right', NameDataQuality: 99, DateCreated: Date.new(2016, 5, 1))
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it 'sets DOB to nil if all client records are blank' do
      source_1.update(DOB: nil, DOBDataQuality: 99)
      source_2.update(DOB: nil, DOBDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:DOB]).to be_nil
    end

    it 'only updates DOB from clients with a value' do
      source_1.update(DOB: @dob_1, DOBDataQuality: 99)
      source_2.update(DOB: nil, DOBDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_1).to eq(@dest_attr[:DOB])
    end

    it 'only updates DOB from clients with a value, even if the quality is nil' do
      source_1.update(DOB: @dob_1, DOBDataQuality: nil)
      source_2.update(DOB: nil, DOBDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_1).to eq(@dest_attr[:DOB])
    end

    it 'chooses the highest quality DOB' do
      source_1.update(DOB: @dob_1, DOBDataQuality: 99)
      source_2.update(DOB: @dob_2, DOBDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_2).to eq(@dest_attr[:DOB])
    end

    it 'chooses the highest quality DOB and treats nil like 99' do
      source_1.update(DOB: @dob_1, DOBDataQuality: nil)
      source_2.update(DOB: @dob_2, DOBDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_2).to eq(@dest_attr[:DOB])
    end

    it "chooses the oldest record's DOB when quality is equivalent" do
      source_1.update(DOB: @dob_1, DOBDataQuality: 9, DateCreated: Date.new(2016, 5, 1))
      source_2.update(DOB: @dob_2, DOBDataQuality: 9, DateCreated: Date.new(2017, 5, 1))
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_1).to eq(@dest_attr[:DOB])
    end

    it 'sets SSN to nil if all client records are blank' do
      source_1.update(SSN: nil, SSNDataQuality: 99)
      source_2.update(SSN: nil, SSNDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:SSN]).to be_nil
    end

    it 'only updates SSN from clients with a value' do
      source_1.update(SSN: @ssn1, SSNDataQuality: 99)
      source_2.update(SSN: nil, SSNDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end
      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@ssn1).to eq(@dest_attr[:SSN])
    end

    it 'chooses the highest quality SSN' do
      source_1.update(SSN: @ssn1, SSNDataQuality: 99)
      source_2.update(SSN: @ssn2, SSNDataQuality: 9)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@ssn2).to eq(@dest_attr[:SSN])
    end

    it "chooses the oldest record's SSN if all have equivalent quality" do
      source_1.update(SSN: @ssn1, SSNDataQuality: 9, DateCreated: Date.new(2017, 5, 1))
      source_2.update(SSN: @ssn2, SSNDataQuality: 9, DateCreated: Date.new(2016, 5, 1))
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@ssn2).to eq(@dest_attr[:SSN])
    end

    it 'overwrites nil veteran status if something is non-blank' do
      source_1.update(VeteranStatus: nil, DateUpdated: 3.days.ago)
      source_2.update(VeteranStatus: 99, DateUpdated: 2.days.ago)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(99).to eq(@dest_attr[:VeteranStatus])
    end

    it 'maintains the newest veteran status if there is no yes' do
      @dest_attr[:VeteranStatus] = @veteran
      source_1.update(VeteranStatus: 99, DateUpdated: 3.days.ago)
      source_2.update(VeteranStatus: 8, DateUpdated: 2.days.ago)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:VeteranStatus]).to eq(8)
    end

    it 'maintains veteran status of yes, even when no is newer' do
      @dest_attr[:VeteranStatus] = @veteran
      source_1.update(VeteranStatus: @civilian, DateUpdated: 1.day.ago)
      source_2.update(VeteranStatus: @veteran, DateUpdated: 2.days.ago)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@veteran).to eq(@dest_attr[:VeteranStatus])
    end

    it 'sets to no when override is set, even if newer answer is yes' do
      @dest_attr[:VeteranStatus] = @veteran
      @dest_attr[:verified_veteran_status] = 'non_veteran'
      source_1.update(VeteranStatus: 99, DateUpdated: 3.days.ago)
      source_2.update(VeteranStatus: @veteran, DateUpdated: 2.days.ago)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:VeteranStatus]).to eq(@civilian)
    end

    it 'updates veteran status with the newest yes/no value' do
      @dest_attr[:VeteranStatus] = @veteran
      source_1.update(VeteranStatus: @civilian, DateUpdated: 2.days.ago)
      source_2.update(VeteranStatus: @veteran, DateUpdated: 1.days.ago)
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*cleanup_columns).map do |row|
        Hash[@cleanup.client_columns.keys.zip(row)]
      end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@veteran).to eq(@dest_attr[:VeteranStatus])
    end

    describe 'Gender Fields' do
      (::HUD.gender_fields - [:GenderNone]).each do |col|
        it "overwrites nil #{col} if something is non-blank" do
          source_1.update(col => nil, DateUpdated: 3.days.ago)
          source_2.update(col => 99, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(99).to eq(@dest_attr[col])
        end

        it "only updates #{col} known value if some client is a known value" do
          @dest_attr[col] = 1
          source_1.update(col => 99, DateUpdated: 3.days.ago)
          source_2.update(col => 8, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end

        it "overwrites #{col} with newest known value" do
          @dest_attr[col] = 0
          source_1.update(col => 1, DateUpdated: 1.day.ago)
          source_2.update(col => 0, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end

        it "uses newest known #{col} value" do
          @dest_attr[col] = 0
          source_1.update(col => 0, DateUpdated: 2.days.ago)
          source_2.update(col => 1, DateUpdated: 1.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end
      end
    end

    describe 'Race Fields' do
      (GrdaWarehouse::Hud::Client.race_fields.map(&:to_sym) - [:RaceNone]).each do |col|
        it "overwrites nil #{col} if something is non-blank" do
          source_1.update(col => nil, DateUpdated: 3.days.ago)
          source_2.update(col => 99, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(99).to eq(@dest_attr[col])
        end

        it "only updates #{col} known value if some client is a known value" do
          @dest_attr[col] = 1
          source_1.update(col => 99, DateUpdated: 3.days.ago)
          source_2.update(col => 8, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end

        it "overwrites #{col} with newest known value" do
          @dest_attr[col] = 0
          source_1.update(col => 1, DateUpdated: 1.day.ago)
          source_2.update(col => 0, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end

        it "uses newest known #{col} value" do
          @dest_attr[col] = 0
          source_1.update(col => 0, DateUpdated: 2.days.ago)
          source_2.update(col => 1, DateUpdated: 1.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end
      end
    end

    describe 'Ethnicity' do
      [:Ethnicity].each do |col|
        it "overwrites nil #{col} if something is non-blank" do
          source_1.update(col => nil, DateUpdated: 3.days.ago)
          source_2.update(col => 99, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(99).to eq(@dest_attr[col])
        end

        it "only updates #{col} known value if some client is a known value" do
          @dest_attr[col] = 1
          source_1.update(col => 99, DateUpdated: 3.days.ago)
          source_2.update(col => 8, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end

        it "overwrites #{col} with newest known value" do
          @dest_attr[col] = 0
          source_1.update(col => 1, DateUpdated: 1.day.ago)
          source_2.update(col => 0, DateUpdated: 2.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end

        it "uses newest known #{col} value" do
          @dest_attr[col] = 0
          source_1.update(col => 0, DateUpdated: 2.days.ago)
          source_2.update(col => 1, DateUpdated: 1.days.ago)
          client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values.map { |column| Arel.sql(column) }).map do |row|
            Hash[@cleanup.client_columns.keys.zip(row)]
          end

          @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
          expect(1).to eq(@dest_attr[col])
        end
      end
    end
  end

  def cleanup_columns
    @cleanup.client_columns.values.map { |c| Arel.sql(c) }
  end
end
