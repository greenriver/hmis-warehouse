require 'rails_helper'

# Included Base before ChronicJustification and WindowNote to fix circular dependency issue
RSpec.describe GrdaWarehouse::ClientNotes::Base, type: :model do
  # Should behave identically for ChronicJustification or WindowNote, although here we test a ChronicJustification instance
  let(:chronic_justification) { create :grda_warehouse_client_notes_chronic_justification }

  describe 'validations' do
    context 'if type present' do
      let(:chronic_justification) { build :grda_warehouse_client_notes_chronic_justification }

      it 'is valid' do
        expect(chronic_justification).to be_valid
      end
    end

    context 'if type missing' do
      let(:chronic_justification) { build :grda_warehouse_client_notes_chronic_justification, type: nil }

      it 'is invalid' do
        expect(chronic_justification).to be_invalid
      end
    end

    context 'if note present' do
      let(:chronic_justification) { build :grda_warehouse_client_notes_chronic_justification }

      it 'is valid' do
        expect(chronic_justification).to be_valid
      end
    end

    context 'if note missing' do
      let(:chronic_justification) { build :grda_warehouse_client_notes_chronic_justification, note: nil }

      it 'is invalid' do
        expect(chronic_justification).to be_invalid
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:client).optional }
  end

  describe 'scopes' do
    let(:chronic_justification1) { create :grda_warehouse_client_notes_chronic_justification }
    let(:chronic_justification2) { create :grda_warehouse_client_notes_chronic_justification }
    let(:window_note1) { create :grda_warehouse_client_notes_window_note }

    it 'returns all Chronic Justifications' do
      expect(GrdaWarehouse::ClientNotes::Base.chronic_justifications).to include(chronic_justification1, chronic_justification2)
      expect(GrdaWarehouse::ClientNotes::Base.chronic_justifications).to_not include(window_note1)
    end

    it 'returns all Window Notes' do
      expect(GrdaWarehouse::ClientNotes::Base.window_notes).to_not include(chronic_justification1, chronic_justification2)
      expect(GrdaWarehouse::ClientNotes::Base.window_notes).to include(window_note1)
    end
  end

  describe 'instance methods' do
    describe 'destroyable_by(user)' do
      let(:chronic_justification_written_by_bob) { create :grda_warehouse_client_notes_chronic_justification, user: bob }
      let(:bob) { create :user }
      let(:sally) { create :user }

      context 'if when user is note author' do
        it 'user can destroy note' do
          expect(chronic_justification_written_by_bob.destroyable_by(bob)).to eq true
        end
      end

      context 'if user is not note author' do
        it 'user cannot destroy note' do
          expect(chronic_justification_written_by_bob.destroyable_by(sally)).to be_falsey
        end
      end
    end
  end
end

RSpec.describe GrdaWarehouse::ClientNotes::ChronicJustification, type: :model do
  let(:chronic_justification) { create :grda_warehouse_client_notes_chronic_justification }

  describe 'instance methods' do
    describe 'type_name' do
      context 'if type is "GrdaWarehouse::ClientNotes::ChronicJustification"' do
        it 'type_name returns "Chronic Justification" ' do
          expect(chronic_justification.type_name).to eq 'Chronic Justification'
        end
      end
    end
  end
end

RSpec.describe GrdaWarehouse::ClientNotes::WindowNote, type: :model do
  let(:window_note) { create :grda_warehouse_client_notes_window_note }

  describe 'instance methods' do
    describe 'type_name' do
      context 'if type is "GrdaWarehouse::ClientNotes::WindowNote"' do
        it 'type_name returns "Window Note" ' do
          expect(window_note.type_name).to eq 'Window Note'
        end
      end
    end
  end
end
