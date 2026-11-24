###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::CohortCopier, type: :model do
  let!(:source) { create(:cohort, name: 'Source') }
  let!(:destination) { create(:cohort, name: 'Destination') }
  let!(:hidden_source) { create(:cohort, name: 'Hidden Source') }
  let!(:client_a) { create(:grda_warehouse_hud_client) }
  let!(:client_b) { create(:grda_warehouse_hud_client) }
  let(:editable_columns) { [CohortColumns::UserString1.new, CohortColumns::UserString2.new, CohortColumns::Notes.new, CohortColumns::Active.new] }
  let(:participate) { [:can_view_cohorts, :can_participate_in_cohorts] }

  def role_with(*permissions)
    create(:role, **permissions.index_with { true })
  end

  def grant_acl(user, permissions, *records)
    collection = create(:collection)
    collection.set_viewables({ cohorts: records.map(&:id) })
    setup_access_control(user, role_with(*permissions), collection)
  end

  def grant_legacy(user, permissions, *records)
    access_group = create(:access_group)
    role_with(*permissions).add(user)
    access_group.add(user)
    records.each { |record| access_group.add_viewable(record) }
  end

  def create_row(cohort, client, **attributes)
    GrdaWarehouse::CohortClient.create!(cohort: cohort, client: client, **attributes)
  end

  def build_copier(columns, cohort_id: source.id, scope: GrdaWarehouse::Cohort.all)
    described_class.new(destination, scope, { cohort_id: cohort_id, columns: columns }, user: user)
  end

  before do
    Collection.maintain_system_groups
    [source, destination, hidden_source].each do |cohort|
      GrdaWarehouse::CohortTab.default_rules.each { |rule| cohort.cohort_tabs.create!(**rule) }
    end
    source.update!(column_state: editable_columns)
    destination.update!(column_state: editable_columns)
  end

  shared_examples 'copier authorization' do
    let!(:source_row) { create_row(source, client_a, user_string_1: 'from source', user_string_2: 'source two', active: true) }
    let!(:destination_row) { create_row(destination, client_a, user_string_1: 'old', user_string_2: 'dest two', active: true) }

    describe 'column allow-list' do
      before { grant(user, participate, source, destination) }

      it 'drops key columns, SQL fragments and non-strings and keeps the allowed column' do
        crafted = ['id', 'cohort_id', 'client_id', 'deleted_at', 'x; drop table cohort_clients', { a: 1 }, 'user_string_1']

        copier = build_copier(crafted)
        expect(copier.columns).to eq(['user_string_1'])

        original_cohort_id = destination_row.cohort_id
        original_client_id = destination_row.client_id
        copier.copy!

        destination_row.reload
        expect(destination_row.attributes.slice('user_string_1', 'user_string_2', 'cohort_id', 'client_id', 'id')).to eq(
          'user_string_1' => 'from source',
          'user_string_2' => 'dest two',
          'cohort_id' => original_cohort_id,
          'client_id' => original_client_id,
          'id' => destination_row.id,
        )
        expect(destination.cohort_clients.count).to eq(1)
      end

      it 'copies only the requested columns when others are also copyable' do
        build_copier(['user_string_1']).copy!

        expect(destination_row.reload.user_string_2).to eq('dest two')
      end

      it 'is not copyable when no requested column is allowed' do
        copier = build_copier(['id', 'cohort_id'])

        expect(copier.columns).to eq([])
        expect(copier).not_to be_copyable
      end

      it 'is copyable when an allowed column is requested' do
        expect(build_copier(['user_string_1'])).to be_copyable
      end

      it 'treats copying a cohort into itself as not copyable' do
        copier = build_copier(['user_string_1'], cohort_id: destination.id)

        expect(copier).not_to be_copyable
      end

      it 'excludes a key column returned by copyable_columns' do
        key_column = CohortColumns::UserString1.new
        key_column.column = 'cohort_id'
        allow(described_class).to receive(:copyable_columns).and_return([key_column])

        copier = build_copier(['cohort_id'])
        copier.copy!

        expect(copier.columns).to eq([])
        expect(destination_row.reload.cohort_id).to eq(destination.id)
      end

      it 'excludes client_id even when the destination column is marked editable' do
        destination.update!(column_state: [CohortColumns::ClientId.new(editable: true)])

        expect(build_copier(['client_id']).columns).to eq([])
      end
    end

    describe 'destination column editability' do
      it 'drops a column the destination marks as not editable for a manage-data user' do
        grant(user, [:can_view_cohorts, :can_manage_cohort_data], source, destination)
        destination.update!(column_state: [CohortColumns::Rank.new(editable: false), CohortColumns::UserString1.new])

        expect(build_copier(['rank', 'user_string_1']).columns).to eq(['user_string_1'])
      end

      it 'drops a hidden destination column' do
        grant(user, participate, source, destination)
        destination.update!(column_state: [CohortColumns::UserString1.new(visible: false), CohortColumns::UserString2.new])

        expect(build_copier(['user_string_1', 'user_string_2']).columns).to eq(['user_string_2'])
      end

      it 'copies nothing for a user who can view but not participate' do
        grant(user, [:can_view_cohorts], source, destination)

        expect(build_copier(['user_string_1']).columns).to eq([])
      end

      it 'drops active for a participant without manage-inactive' do
        grant(user, participate, source, destination)

        expect(build_copier(['active', 'user_string_1']).columns).to eq(['user_string_1'])
      end
    end

    describe 'source visibility' do
      it 'raises not-found for a source the user cannot view even when the scope includes it' do
        grant(user, participate, source, destination)
        create_row(hidden_source, client_a, user_string_1: 'secret')

        expect do
          build_copier(['user_string_1'], cohort_id: hidden_source.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
        expect(destination_row.reload.user_string_1).to eq('old')
      end
    end

    describe 'active changes' do
      it 'logs one deactivate change when copying active from true to false' do
        grant(user, participate + [:can_manage_inactive_cohort_clients], source, destination)
        source_row.update!(active: false)

        expect { build_copier(['active']).copy! }.to change(GrdaWarehouse::CohortClientChange, :count).by(1)

        change = GrdaWarehouse::CohortClientChange.last
        expect(change.attributes.slice('change', 'user_id', 'cohort_id', 'cohort_client_id')).to eq(
          'change' => 'deactivate',
          'user_id' => user.id,
          'cohort_id' => destination.id,
          'cohort_client_id' => destination_row.id,
        )
        expect(destination_row.reload.active).to be(false)
      end

      it 'logs nothing when active is unchanged' do
        grant(user, participate + [:can_manage_inactive_cohort_clients], source, destination)

        expect { build_copier(['active']).copy! }.not_to change(GrdaWarehouse::CohortClientChange, :count)
      end
    end

    describe 'notes' do
      let!(:note_author) { create(:user) }
      let!(:note) { GrdaWarehouse::CohortClientNote.create!(cohort_client: source_row, note: 'from source', user: note_author) }

      it 'copies notes with the original author when notes are allowed' do
        grant(user, participate, source, destination)

        build_copier(['notes']).copy!

        copied = destination_row.cohort_client_notes.to_a
        expect(copied.map { |n| n.attributes.slice('note', 'user_id') }).to eq([{ 'note' => 'from source', 'user_id' => note_author.id }])
      end

      it 'copies each note once across repeated copies' do
        grant(user, participate, source, destination)

        2.times { build_copier(['notes']).copy! }

        expect(destination_row.cohort_client_notes.count).to eq(1)
      end

      it 'ignores notes when the destination does not allow them' do
        grant(user, participate, source, destination)
        destination.update!(column_state: [CohortColumns::UserString1.new])

        copier = build_copier(['notes', 'user_string_1'])
        copier.copy!

        expect(copier.columns).to eq(['user_string_1'])
        expect(destination_row.cohort_client_notes.count).to eq(0)
      end
    end

    describe 'soft-deleted warehouse clients' do
      it 'skips destination rows whose client is deleted and copies the rest' do
        grant(user, participate, source, destination)
        create_row(source, client_b, user_string_1: 'b from source')
        row_b = create_row(destination, client_b, user_string_1: 'b old')
        client_b.destroy

        build_copier(['user_string_1']).copy!

        expect(destination_row.reload.user_string_1).to eq('from source')
        expect(row_b.reload.user_string_1).to eq('b old')
      end
    end

    describe 'row visibility' do
      let!(:inactive_destination_row) { create_row(destination, client_b, user_string_1: 'inactive old', active: false) }
      let!(:inactive_source_row) { create_row(source, client_b, user_string_1: 'inactive source', active: false) }

      it 'leaves inactive destination rows alone for a user without view-inactive' do
        grant(user, participate, source, destination)

        build_copier(['user_string_1']).copy!

        expect(destination_row.reload.user_string_1).to eq('from source')
        expect(inactive_destination_row.reload.user_string_1).to eq('inactive old')
      end

      it 'copies into inactive destination rows for a user with view-inactive' do
        grant(user, participate + [:can_view_inactive_cohort_clients], source, destination)

        build_copier(['user_string_1']).copy!

        expect(inactive_destination_row.reload.user_string_1).to eq('inactive source')
      end
    end
  end

  context 'with an ACL user' do
    let(:user) { create(:acl_user) }

    def grant(...) = grant_acl(...)

    include_examples 'copier authorization'

    describe 'source row visibility' do
      let!(:source_row) { create_row(source, client_a, user_string_1: 'inactive source', active: false) }
      let!(:destination_row) { create_row(destination, client_a, user_string_1: 'old', active: true) }

      before do
        GrdaWarehouse::CohortClientNote.create!(cohort_client: source_row, note: 'inactive note', user: user)
        grant(user, participate, destination)
      end

      it 'does not copy values or notes from inactive source rows without view-inactive on the source' do
        grant(user, [:can_view_cohorts], source)

        build_copier(['user_string_1', 'notes']).copy!

        expect(destination_row.reload.user_string_1).to eq('old')
        expect(destination_row.cohort_client_notes.count).to eq(0)
      end

      it 'copies them with view-inactive on the source' do
        grant(user, [:can_view_cohorts, :can_view_inactive_cohort_clients], source)

        build_copier(['user_string_1', 'notes']).copy!

        expect(destination_row.reload.user_string_1).to eq('inactive source')
        expect(destination_row.cohort_client_notes.pluck(:note)).to eq(['inactive note'])
      end
    end
  end

  context 'with a legacy user' do
    let(:user) { create(:user) }

    def grant(...) = grant_legacy(...)

    include_examples 'copier authorization'
  end
end
