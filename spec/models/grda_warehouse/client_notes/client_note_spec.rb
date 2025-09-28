# frozen_string_literal: false

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
    it { expect(subject).to belong_to(:user).optional }
    it { expect(subject).to belong_to(:client).optional }
  end

  describe 'scopes' do
    let!(:chronic_justification1) { create :grda_warehouse_client_notes_chronic_justification }
    let!(:chronic_justification2) { create :grda_warehouse_client_notes_chronic_justification }
    let!(:window_note1) { create :grda_warehouse_client_notes_window_note }
    let!(:expired_alert) { create :grda_warehouse_client_notes_expired_alert }
    let!(:active_alert) { create :grda_warehouse_client_notes_active_alert }
    let!(:no_expiration_alert) { create :grda_warehouse_client_notes_no_expiration }
    let!(:expire_today_alert) { create :grda_warehouse_client_notes_expiration_today }

    it 'returns all Chronic Justifications' do
      expect(GrdaWarehouse::ClientNotes::Base.chronic_justifications).to include(chronic_justification1, chronic_justification2)
      expect(GrdaWarehouse::ClientNotes::Base.chronic_justifications).to_not include(window_note1, expired_alert, active_alert, no_expiration_alert, expire_today_alert)
    end

    it 'returns all Window Notes' do
      expect(GrdaWarehouse::ClientNotes::Base.window_notes).to_not include(chronic_justification1, chronic_justification2, expired_alert, active_alert, no_expiration_alert, expire_today_alert)
      expect(GrdaWarehouse::ClientNotes::Base.window_notes).to include(window_note1)
    end

    it 'returns all Alerts' do
      expect(GrdaWarehouse::ClientNotes::Base.alerts).to include(expired_alert, active_alert, no_expiration_alert, expire_today_alert)
      expect(GrdaWarehouse::ClientNotes::Base.alerts).to_not include(window_note1, chronic_justification1, chronic_justification2)
    end

    it 'returns all Active Notes' do
      expect(GrdaWarehouse::ClientNotes::Base.active).to include(window_note1, chronic_justification1, chronic_justification2, active_alert, no_expiration_alert)
      expect(GrdaWarehouse::ClientNotes::Base.active).to_not include(expired_alert, expire_today_alert)
    end

    it 'returns all Expired Notes' do
      expect(GrdaWarehouse::ClientNotes::Base.expired).to include(expired_alert, expire_today_alert)
      expect(GrdaWarehouse::ClientNotes::Base.expired).to_not include(window_note1, chronic_justification1, chronic_justification2, active_alert, no_expiration_alert)
    end

    it 'expired notes are expired' do
      GrdaWarehouse::ClientNotes::Base.expired.each do |note|
        expect(note.expired?).to eq true
      end
    end

    it 'active notes are active' do
      GrdaWarehouse::ClientNotes::Base.active.each do |note|
        expect(note.active?).to eq true
      end
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
