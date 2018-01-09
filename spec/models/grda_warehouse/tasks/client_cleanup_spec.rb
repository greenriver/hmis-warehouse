require 'rails_helper'

DEFAULT_DEST_ATTR = {
  FirstName: 'Blair', 
  LastName: 'Abbott', 
  SSN: '555-55-5555', 
  DOB: '06-12-1978', 
  VeteranStatus: nil,
  Gender: nil
}

RSpec.describe GrdaWarehouse::Tasks::ClientCleanup, type: :model do
  describe 'When Updating destination records from client sources' do
    before(:each) do
      @dest_attr = DEFAULT_DEST_ATTR.dup
    end

    before(:all) do
      @mark = Date.new(1978, 6, 12)
      @beth = Date.new(1977, 10, 31)
      @ssn1 = '123-45-6789'
      @ssn2 = '987-65-4321'
      @veteran = '1'
      @civilian = '0'
    end

    it "doesn't select blank names" do
      client_sources = [
        {FirstName: 'Correct', LastName: 'Update', NameDataQuality: 99},
        {FirstName: '', LastName: '', NameDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:FirstName]).to eq('Correct')
      expect(@dest_attr[:LastName]).to eq('Update')
    end

    it "keeps the original name fields if all sources are blank" do
      client_sources = [
        {FirstName: '', LastName: '', NameDataQuality: 99},
        {FirstName: '', LastName: '', NameDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('Blair').to eq(@dest_attr[:FirstName])
      expect('Abbott').to eq(@dest_attr[:LastName])
    end

    it "chooses the first and last name of the highest quality record" do
      client_sources = [
        {FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 99},
        {FirstName: 'Right', LastName: 'Right', NameDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "chooses the oldest record's names when quality is equivalent" do
      client_sources = [
        {FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 9, DateCreated: Date.new(2017,5,1)},
        {FirstName: 'Right', LastName: 'Right', NameDataQuality: 9, DateCreated: Date.new(2016,5,1)}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('Right').to eq(@dest_attr[:FirstName])
      expect('Right').to eq(@dest_attr[:LastName])
    end

    it "sets DOB to nil if all client records are blank" do
      client_sources = [
        {DOB: nil, DOBDataQuality: 99},
        {DOB: nil, DOBDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:DOB]).to be_nil
    end

    it "only updates DOB from clients with a value" do
      client_sources = [
        {DOB: @mark, DOBDataQuality: 99},
        {DOB: nil, DOBDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@mark).to eq(@dest_attr[:DOB])
    end

    it "chooses the highest quality DOB" do
      client_sources = [
        {DOB: @mark, DOBDataQuality: 99},
        {DOB: @beth, DOBDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@beth).to eq(@dest_attr[:DOB])
    end

    it "chooses the oldest record's DOB when quality is equivalent" do
      client_sources = [
        {DOB: @mark, DOBDataQuality: 9, DateCreated: Date.new(2016,5,1)},
        {DOB: @beth, DOBDataQuality: 9, DateCreated: Date.new(2017,5,1)}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@mark).to eq(@dest_attr[:DOB])
    end

    it "sets SSN to nil if all client records are blank" do
      client_sources = [
        {SSN: nil, SSNDataQuality: 99},
        {SSN: nil, SSNDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@dest_attr[:SSN]).to be_nil
    end

    it "only updates SSN from clients with a value" do
      client_sources = [
        {SSN: @ssn1, SSNDataQuality: 99},
        {SSN: nil, SSNDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@ssn1).to eq(@dest_attr[:SSN])
    end

    it "chooses the highest quality SSN" do 
      client_sources = [
        {SSN: @ssn1, SSNDataQuality: 99},
        {SSN: @ssn2, SSNDataQuality: 9}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@ssn2).to eq(@dest_attr[:SSN])
    end

    it "chooses the oldest record's SSN if all have equivalent quality" do
      client_sources = [
        {SSN: @ssn1, SSNDataQuality: 9, DateCreated: Date.new(2017,5,1)},
        {SSN: @ssn2, SSNDataQuality: 9, DateCreated: Date.new(2016,5,1)}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@ssn2).to eq(@dest_attr[:SSN])
    end

    it "overwrites nil veteran status if something is non-blank" do
      client_sources = [
        {VeteranStatus: nil, DateUpdated: 3.days.ago},
        {VeteranStatus: '99', DateUpdated: 2.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('99').to eq(@dest_attr[:VeteranStatus])
    end

    it 'only updates veteran status yes/no if some client is yes/no' do
      @dest_attr[:VeteranStatus] = @veteran
      client_sources = [
        {VeteranStatus: '99', DateUpdated: 3.days.ago},
        {VeteranStatus: '8', DateUpdated: 2.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@veteran).to eq(@dest_attr[:VeteranStatus])
    end

    it "overwrites veteran status with the newest yes/no value" do
      @dest_attr[:VeteranStatus] = @veteran
      client_sources = [
        {VeteranStatus: @civilian, DateUpdated: 1.day.ago},
        {VeteranStatus: @veteran, DateUpdated: 2.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@civilian).to eq(@dest_attr[:VeteranStatus])
    end

    it "updates veteran status with the newest yes/no value" do
      @dest_attr[:VeteranStatus] = @veteran
      client_sources = [
        {VeteranStatus: @civilian, DateUpdated: 2.days.ago},
        {VeteranStatus: @veteran, DateUpdated: 1.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect(@veteran).to eq(@dest_attr[:VeteranStatus])
    end

    it "overwrites nil gender if something is non-blank" do
      client_sources = [
        {Gender: nil, DateUpdated: 3.days.ago},
        {Gender: '99', DateUpdated: 2.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('99').to eq(@dest_attr[:Gender])
    end

    it 'only updates gender known value if some client is a known value' do
      @dest_attr[:Gender] = '3'
      client_sources = [
        {Gender: '99', DateUpdated: 3.days.ago},
        {Gender: '8', DateUpdated: 2.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('3').to eq(@dest_attr[:Gender])
    end

    it 'overwrites gender with newest known value' do
      @dest_attr[:Gender] = '3'
      client_sources = [
        {Gender: '1', DateUpdated: 1.day.ago},
        {Gender: '2', DateUpdated: 2.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('1').to eq(@dest_attr[:Gender])
    end

    it 'uses newest known gender value' do
      @dest_attr[:Gender] = '4'
      client_sources = [
        {Gender: '1', DateUpdated: 2.days.ago},
        {Gender: '4', DateUpdated: 1.days.ago}
      ]
      GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(@dest_attr, client_sources)
      expect('4').to eq(@dest_attr[:Gender])
    end
  end
end
