require 'rails_helper'

RSpec.describe GrdaWarehouse::UserClient, type: :model do

  let(:user_client) { GrdaWarehouse::UserClient }
  let(:end_date_past) { build :grda_warehouse_user_client, end_date: Date.yesterday, user: user, client: client}
  let(:end_date_future) { build :grda_warehouse_user_client, end_date: Date.tomorrow, user: user, client: client}
  let(:end_date_nil) { build :grda_warehouse_user_client, end_date: nil, user: user, client: client}
  let(:user) { create :user }
  let(:client) { create :grda_warehouse_hud_client }
  
  describe 'validations' do
    describe 'date_range' do
      context 'when end_date in past' do
        it 'is invalid' do
          expect( end_date_past ).to be_invalid
        end
        it 'adds an error message' do
          end_date_past.valid?
          expect( end_date_past.errors.size ).to eq 1
        end 
      end

      context 'when end_date in future' do
        it 'is valid' do
          expect( end_date_future ).to be_valid
        end
      end

      context 'when end_date is nil' do
        it 'is valid' do
          expect( end_date_nil ).to be_valid
        end
      end
    end
  end

  describe 'scopes' do

    before(:each) do
      end_date_past.save( validate: false ) # to get invalid record in
      end_date_future.save
      end_date_nil.save
    end

    describe 'active' do
      it 'returns 2 records' do
        expect( user_client.active.count ).to eq 2
      end
      it 'returns active records' do
        expect( user_client.active.ids ).to match [end_date_future.id, end_date_nil.id]
      end
    end

    describe 'expired' do
      it 'returns 1 record' do
        expect( user_client.expired.count ).to eq 1
      end
      it 'returns expired record' do
        expect( user_client.expired.ids ).to eq [end_date_past.id]
      end
    end
  end

  describe 'expired?' do

    before(:each) do
      end_date_past.save
      end_date_future.save
      end_date_nil.save
    end

    context 'when end_date in past' do
      it 'returns true' do
        expect( end_date_past.expired? ).to be_truthy
      end
    end
    context 'when end_date nil' do
      it 'returns false' do
        expect( end_date_future.expired? ).to be_falsey
      end
    end
    context 'when end_date in future' do
      it 'returns false' do
        expect( end_date_nil.expired? ).to be_falsey
      end
    end
  end



end
