###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::RestrictedRecord, type: :model do
  include_context 'hmis base setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:user2) { create(:user).related_hmis_user(ds1) }

  def restriction_versions
    GrdaWarehouse.paper_trail_versions.
      where(item_type: 'Hmis::RestrictedRecord', client_id: c1.id).
      order(:id)
  end

  describe '.mark!' do
    it 'creates a row and an audit version' do
      expect { described_class.mark!(c1, user: hmis_user) }.
        to change { restriction_versions.count }.by(1)

      expect(restriction_versions.last.event).to eq('create')
      expect(c1.reload).to be_restricted
    end

    it 'rejects unsupported restrictable types' do
      expect { described_class.mark!(p1, user: hmis_user) }.to raise_error(ArgumentError)
    end

    context 'when the record is already restricted' do
      let!(:existing) { described_class.mark!(c1, user: hmis_user) }

      it 'is a no-op rather than raising on the unique index' do
        expect { described_class.mark!(c1.reload, user: user2) }.
          not_to(change { described_class.with_deleted.count })
      end

      it 'leaves created_by and the audit trail untouched' do
        expect { described_class.mark!(c1.reload, user: user2) }.
          not_to(change { restriction_versions.count })

        expect(existing.reload.created_by_id).to eq(hmis_user.id)
      end
    end

    context 'when the record was restricted before and then unmarked' do
      let!(:first) { described_class.mark!(c1, user: hmis_user) }
      before(:each) { described_class.unmark!(c1.reload) }

      it 'creates a second row instead of reviving the first' do
        second = described_class.mark!(c1.reload, user: user2)

        expect(second.id).not_to eq(first.id)
        expect(described_class.with_deleted.find(first.id)).to be_deleted
        expect(second.created_by_id).to eq(user2.id)
      end

      it 'writes an audit version for the second restriction' do
        expect { described_class.mark!(c1.reload, user: user2) }.
          to change { restriction_versions.where(event: 'create').count }.by(1)
      end

      it 'reports the record as restricted with the earlier row still soft-deleted' do
        described_class.mark!(c1.reload, user: user2)

        expect(c1.reload).to be_restricted
        expect(described_class.with_deleted.where(restrictable: c1).count).to eq(2)
      end
    end
  end

  describe '.unmark!' do
    let!(:existing) { described_class.mark!(c1, user: hmis_user) }

    it 'soft-deletes the row and writes an audit version' do
      expect { described_class.unmark!(c1.reload) }.
        to change { restriction_versions.where(event: 'destroy').count }.by(1)

      expect(described_class.with_deleted.find(existing.id)).to be_deleted
      expect(c1.reload).not_to be_restricted
    end
  end
end
