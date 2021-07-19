require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  let(:destination_ds) { create :grda_warehouse_data_source }
  let(:source_ds) { create :data_source_fixed_id }
  let(:sources) { create_list :hud_client, 2, data_source_id: source_ds.id }

  let(:prev_destination) { create :hud_client, data_source_id: destination_ds.id }
  let!(:prev_chronic_notes) do
    create_list :grda_warehouse_client_notes_chronic_justification, 3, client_id: prev_destination.id
  end
  let!(:prev_window_notes) do
    create_list :grda_warehouse_client_notes_window_note, 2, client_id: prev_destination.id
  end
  let!(:prev_hud_chronic) { create :hud_chronic, client_id: prev_destination.id, date: 1.months.ago }
  let!(:prev_chronic) { create :chronic, client_id: prev_destination.id, date: 1.months.ago }

  let(:new_destination) { create :hud_client, data_source_id: destination_ds.id }
  let!(:new_chronic_notes) do
    create_list :grda_warehouse_client_notes_chronic_justification, 3, client_id: new_destination.id
  end
  let!(:new_window_notes) do
    create_list :grda_warehouse_client_notes_window_note, 2, client_id: new_destination.id
  end
  let!(:new_hud_chronic) { create :hud_chronic, client_id: new_destination.id, date: 1.weeks.ago }
  let!(:new_chronic) { create :chronic, client_id: new_destination.id, date: 1.weeks.ago }

  let(:user) { create :user }

  describe 'prior to being merged' do
    before(:each) do
      GrdaWarehouse::WarehouseClient.create(
        destination_id: prev_destination.id,
        source_id: sources.first.id,
        id_in_source: 1,
      )

      GrdaWarehouse::WarehouseClient.create(
        destination_id: new_destination.id,
        source_id: sources.last.id,
        id_in_source: 1,
      )
    end
    after(:all) do
      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end
    it 'previous client has 5 notes' do
      expect(prev_destination.notes.count).to eq 5
    end
    it 'previous client has 1 hud chronic' do
      expect(GrdaWarehouse::HudChronic.where(client_id: prev_destination.id).count).to eq 1
    end
    it 'previous client has 1 chronic' do
      expect(GrdaWarehouse::Chronic.where(client_id: prev_destination.id).count).to eq 1
    end
    it 'new destination has 5 notes' do
      expect(new_destination.notes.count).to eq 5
    end
    it 'new client has 1 hud chronic' do
      expect(GrdaWarehouse::HudChronic.where(client_id: new_destination.id).count).to eq 1
    end
    it 'new client has 1 chronic' do
      expect(GrdaWarehouse::Chronic.where(client_id: new_destination.id).count).to eq 1
    end
    describe 'after being merged' do
      before(:each) do
        new_destination.merge_from(prev_destination, reviewed_by: user, reviewed_at: Time.now)
      end
      describe 'any notes belonging to the previous client' do
        it 'should now belong to the new destination client' do
          expect(new_destination.notes.count).to eq 10
        end
        it 'should no longer be attached to the previous client' do
          expect(prev_destination.notes.count).to eq 0
        end
      end
      describe 'notes previously belonging to the new destination client' do
        it 'should still be attached to the new destination client' do
          expect(new_destination.notes.pluck(:id)).to include(*(new_chronic_notes.map(&:id) + new_window_notes.map(&:id)))
        end
      end

      it 'previous client has no hud chronic' do
        expect(GrdaWarehouse::HudChronic.where(client_id: prev_destination.id).count).to eq 0
      end
      it 'previous client has no chronic' do
        expect(GrdaWarehouse::Chronic.where(client_id: prev_destination.id).count).to eq 0
      end
      it 'new client has 2 hud chronic' do
        expect(GrdaWarehouse::HudChronic.where(client_id: new_destination.id).count).to eq 2
      end
      it 'new client has 2 chronic' do
        expect(GrdaWarehouse::Chronic.where(client_id: new_destination.id).count).to eq 2
      end
    end
  end
end
