require 'rails_helper'

DEFAULT_DEST_ATTR = {
  FirstName: 'Blair', 
  LastName: 'Abbott', 
  SSN: '555555555', 
  DOB: '1978-06-12', 
  VeteranStatus: nil,
  Gender: nil
}

RSpec.describe GrdaWarehouse::Tasks::ClientCleanup, type: :model do
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
      source_1.update({FirstName: 'Correct', LastName: 'Update', NameDataQuality: 99})
      source_2.update({FirstName: '', LastName: '', NameDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:FirstName]).to eq('Correct')
      expect(@dest_attr[:LastName]).to eq('Update')
    end

    it "keeps the original name fields if all sources are blank" do
      source_1.update({FirstName: '', LastName: '', NameDataQuality: 99})
      source_2.update({FirstName: '', LastName: '', NameDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end
      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:FirstName]).to eq('Blair')
      expect(@dest_attr[:LastName]).to eq('Abbott')
    end

    it "chooses the first and last name of the highest quality record" do
      source_1.update({FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 99})
      source_2.update({FirstName: 'Right', LastName: 'Right', NameDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "chooses the first and last name of the highest quality record, even if the quality is nil" do
      source_1.update({FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil})
      source_2.update({FirstName: 'Right', LastName: 'Right', NameDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "chooses the first and last name of the highest quality record, and treats nil like 99" do
      source_1.update({FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil})
      source_2.update({FirstName: 'Right', LastName: 'Right', NameDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "chooses the oldest record's names when quality is equivalent" do
      source_1.update({FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 9, DateCreated: Date.new(2017,5,1)})
      source_2.update({FirstName: 'Right', LastName: 'Right', NameDataQuality: 9, DateCreated: Date.new(2016,5,1)})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "chooses the oldest, and treats nil like 99" do
      source_1.update({FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: nil, DateCreated: Date.new(2017,5,1)})
      source_2.update({FirstName: 'Right', LastName: 'Right', NameDataQuality: 99, DateCreated: Date.new(2016,5,1)})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "sets DOB to nil if all client records are blank" do
      source_1.update({DOB: nil, DOBDataQuality: 99})
      source_2.update({DOB: nil, DOBDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:DOB]).to be_nil
    end

    it "only updates DOB from clients with a value" do
      source_1.update({DOB: @dob_1, DOBDataQuality: 99})
      source_2.update({DOB: nil, DOBDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_1).to eq(@dest_attr[:DOB])
    end

    it "only updates DOB from clients with a value, even if the quality is nil" do
      source_1.update({DOB: @dob_1, DOBDataQuality: nil})
      source_2.update({DOB: nil, DOBDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_1).to eq(@dest_attr[:DOB])
    end

    it "chooses the highest quality DOB" do
      source_1.update({DOB: @dob_1, DOBDataQuality: 99})
      source_2.update({DOB: @dob_2, DOBDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_2).to eq(@dest_attr[:DOB])
    end

    it "chooses the highest quality DOB and treats nil like 99" do
      source_1.update({DOB: @dob_1, DOBDataQuality: nil})
      source_2.update({DOB: @dob_2, DOBDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_2).to eq(@dest_attr[:DOB])
    end

    it "chooses the oldest record's DOB when quality is equivalent" do
      source_1.update({DOB: @dob_1, DOBDataQuality: 9, DateCreated: Date.new(2016,5,1)})
      source_2.update({DOB: @dob_2, DOBDataQuality: 9, DateCreated: Date.new(2017,5,1)})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dob_1).to eq(@dest_attr[:DOB])
    end

    it "sets SSN to nil if all client records are blank" do
      source_1.update({SSN: nil, SSNDataQuality: 99})
      source_2.update({SSN: nil, SSNDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:SSN]).to be_nil
    end

    it "only updates SSN from clients with a value" do
      source_1.update({SSN: @ssn1, SSNDataQuality: 99})
      source_2.update({SSN: nil, SSNDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@ssn1).to eq(@dest_attr[:SSN])
    end

    it "chooses the highest quality SSN" do 
      source_1.update({SSN: @ssn1, SSNDataQuality: 99})
      source_2.update({SSN: @ssn2, SSNDataQuality: 9})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@ssn2).to eq(@dest_attr[:SSN])
    end

    it "chooses the oldest record's SSN if all have equivalent quality" do
      source_1.update({SSN: @ssn1, SSNDataQuality: 9, DateCreated: Date.new(2017,5,1)})
      source_2.update({SSN: @ssn2, SSNDataQuality: 9, DateCreated: Date.new(2016,5,1)})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@ssn2).to eq(@dest_attr[:SSN])
    end

    it "overwrites nil veteran status if something is non-blank" do
      source_1.update({VeteranStatus: nil, DateUpdated: 3.days.ago})
      source_2.update({VeteranStatus: 99, DateUpdated: 2.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(99).to eq(@dest_attr[:VeteranStatus])
    end

    it 'only updates veteran status yes/no if some client is yes/no' do
      @dest_attr[:VeteranStatus] = @veteran
      source_1.update({VeteranStatus: 99, DateUpdated: 3.days.ago})
      source_2.update({VeteranStatus: 8, DateUpdated: 2.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:VeteranStatus]).to eq(@veteran)
    end

    it "overwrites veteran status with the newest yes/no value" do
      @dest_attr[:VeteranStatus] = @veteran
      source_1.update({VeteranStatus: @civilian, DateUpdated: 1.day.ago})
      source_2.update({VeteranStatus: @veteran, DateUpdated: 2.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@civilian).to eq(@dest_attr[:VeteranStatus])
    end

    it "updates veteran status with the newest yes/no value" do
      @dest_attr[:VeteranStatus] = @veteran
      source_1.update({VeteranStatus: @civilian, DateUpdated: 2.days.ago})
      source_2.update({VeteranStatus: @veteran, DateUpdated: 1.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(@veteran).to eq(@dest_attr[:VeteranStatus])
    end

    it "overwrites nil gender if something is non-blank" do
      source_1.update({Gender: nil, DateUpdated: 3.days.ago})
      source_2.update({Gender: 99, DateUpdated: 2.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(99).to eq(@dest_attr[:Gender])
    end

    it 'only updates gender known value if some client is a known value' do
      @dest_attr[:Gender] = 3
      source_1.update({Gender: 99, DateUpdated: 3.days.ago})
      source_2.update({Gender: 8, DateUpdated: 2.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(3).to eq(@dest_attr[:Gender])
    end

    it 'overwrites gender with newest known value' do
      @dest_attr[:Gender] = 3
      source_1.update({Gender: 1, DateUpdated: 1.day.ago})
      source_2.update({Gender: 2, DateUpdated: 2.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(1).to eq(@dest_attr[:Gender])
    end

    it 'uses newest known gender value' do
      @dest_attr[:Gender] = 4
      source_1.update({Gender: 1, DateUpdated: 2.days.ago})
      source_2.update({Gender: 4, DateUpdated: 1.days.ago})
      client_sources = GrdaWarehouse::Hud::Client.where(id: [source_1.id, source_2.id]).pluck(*@cleanup.client_columns.values).
        map do |row|
          Hash[@cleanup.client_columns.keys.zip(row)]
        end

      @dest_attr = @cleanup.choose_attributes_from_sources(@dest_attr, client_sources)
      expect(4).to eq(@dest_attr[:Gender])
    end
  end
end
