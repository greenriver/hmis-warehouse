###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

model = GrdaWarehouse::DataSource
RSpec.describe model, type: :model do
  # set up hierarchy like so
  #
  # data source:       ds1            ds2
  #                  /     \        /    \
  # organization:   o1     o2      o3    o4
  #                / \     /\     / \   /  \
  # project:     p1  p2  p3 p4  p5  p6 p7  p8

  let!(:admin_role) { create :admin_role }
  let!(:can_view_projects) { create :role, can_view_projects: true }

  let!(:user) { create :acl_user }

  let!(:ds1) { create :source_data_source, id: 1 }
  let!(:ds2) { create :source_data_source, id: 2 }

  let!(:o1) { create :hud_organization, data_source_id: ds1.id }
  let!(:o2) { create :hud_organization, data_source_id: ds1.id }
  let!(:o3) { create :hud_organization, data_source_id: ds2.id }
  let!(:o4) { create :hud_organization, data_source_id: ds2.id }

  let!(:p1) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:p2) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let!(:p3) { create :hud_project, data_source_id: ds1.id, OrganizationID: o2.OrganizationID }
  let!(:p4) { create :hud_project, data_source_id: ds1.id, OrganizationID: o2.OrganizationID }
  let!(:p5) { create :hud_project, data_source_id: ds2.id, OrganizationID: o3.OrganizationID }
  let!(:p6) { create :hud_project, data_source_id: ds2.id, OrganizationID: o3.OrganizationID }
  let!(:p7) { create :hud_project, data_source_id: ds2.id, OrganizationID: o4.OrganizationID }
  let!(:p8) { create :hud_project, data_source_id: ds2.id, OrganizationID: o4.OrganizationID }

  let!(:pcoc1) { create :hud_project_coc, data_source_id: ds1.id, ProjectID: p1.ProjectID, CoCCode: 'XX-500' }
  let!(:pcoc2) { create :hud_project_coc, data_source_id: ds2.id, ProjectID: p5.ProjectID, CoCCode: 'XX-501' }

  let!(:pg1) { create :project_access_group, projects: [p1] }
  let!(:pg2) { create :project_access_group, projects: [p1, p5] }

  let!(:empty_collection) { create :collection }

  user_ids = ->(user) { model.viewable_by(user, permission: :can_view_projects).pluck(:id).sort }
  ids = ->(*sources) { sources.map(&:id).sort }

  # A fixed instant clear of midnight and of any daylight-saving transition, so the 24-hour
  # stall boundary and the `.to_date` assertions in the stall examples can't drift.
  def import_stall_evaluated_at
    Time.zone.local(2026, 6, 15, 12, 0, 0)
  end

  def build_data_source_with_upload(file_count:, completed_at:)
    data_source = create(:source_data_source)
    create(:grda_warehouse_hmis_import_config, data_source: data_source, file_count: file_count)
    create(:grda_warehouse_upload, data_source: data_source, user: User.system_user, percent_complete: 100, completed_at: completed_at)
    data_source
  end

  describe 'scopes' do
    describe 'viewability' do
      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          Collection.maintain_system_groups
          setup_access_control(user, admin_role, Collection.system_collection(:data_sources))
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to project' do
        it 'sees ds1' do
          empty_collection.set_viewables({ projects: [p1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ projects: [p1.id, p5.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to organization' do
        it 'sees ds1' do
          empty_collection.set_viewables({ organizations: [o1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ organizations: [o1.id, o3.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to data source' do
        it 'sees ds1' do
          empty_collection.set_viewables({ data_sources: [ds1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ data_sources: [ds1.id, ds2.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to projet group' do
        it 'sees ds1' do
          empty_collection.set_viewables({ project_access_groups: [pg1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ project_access_groups: [pg1.id, pg2.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end

      describe 'user assigned to CoC XX-500' do
        it 'sees ds1' do
          empty_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: ['XX-500']).pluck(:id) })
          setup_access_control(user, can_view_projects, empty_collection)

          expect(user_ids[user]).to eq ids[ds1]
        end
        it 'sees ds1 and ds2' do
          empty_collection.set_viewables({ coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: ['XX-500', 'XX-501']).pluck(:id) })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(user_ids[user]).to eq ids[ds1, ds2]
        end
      end
    end

    describe 'editability' do
      let!(:can_edit_data_sources_role) { create :role, name: 'can edit data sources', can_edit_data_sources: true }

      editable_ids = ->(user) { model.editable_by(user).pluck(:id).sort }

      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.editable_by(user).exists?).to be false
        end
      end

      describe 'user with a view-only role granted access to the data source' do
        it 'is excluded, since editable_by requires can_edit_data_sources' do
          empty_collection.set_viewables({ data_sources: [ds1.id] })
          setup_access_control(user, can_view_projects, empty_collection)
          expect(model.editable_by(user).exists?).to be false
        end
      end

      describe 'user with edit permission assigned to a data source' do
        it 'sees ds1, excluding ds2' do
          empty_collection.set_viewables({ data_sources: [ds1.id] })
          setup_access_control(user, can_edit_data_sources_role, empty_collection)
          expect(editable_ids[user]).to eq ids[ds1]
        end
      end

      describe 'user with edit permission assigned to an organization' do
        it 'does not grant access to the organization\'s data source, unlike viewable_by' do
          empty_collection.set_viewables({ organizations: [o1.id] })
          setup_access_control(user, can_edit_data_sources_role, empty_collection)
          expect(model.editable_by(user).exists?).to be false
        end
      end

      describe 'user with edit permission assigned to a project' do
        it 'does not grant access to the project\'s data source, unlike viewable_by' do
          empty_collection.set_viewables({ projects: [p1.id] })
          setup_access_control(user, can_edit_data_sources_role, empty_collection)
          expect(model.editable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          Collection.maintain_system_groups
          setup_access_control(user, admin_role, Collection.system_collection(:data_sources))
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees both' do
          expect(editable_ids[user]).to eq ids[ds1, ds2]
        end
      end
    end
  end

  describe '.stalled_dates_by_id' do
    around do |example|
      travel_to(import_stall_evaluated_at) { example.run }
    end

    describe 'when expecting one file' do
      it 'is not stalled when there are no prior imports in the past 6 months' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 7.months.ago)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(nil)
      end

      it 'is stalled, since its single most recent upload, when the last import was over 24 hours ago' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
        most_recent_completed_at = 30.hours.ago
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: most_recent_completed_at)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 50.hours.ago)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(most_recent_completed_at.to_date)
      end

      it 'is not stalled when there was an import within the last 24 hours' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(nil)
      end
    end

    describe 'when expecting multiple files' do
      it 'is not stalled when there are no prior imports in the past 6 months' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 3)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 7.months.ago)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(nil)
      end

      it 'is stalled since the oldest of the most recent N uploads, when they span more than 24 hours' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 3)
        oldest_of_the_three = 50.hours.ago
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 26.hours.ago)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: oldest_of_the_three)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(oldest_of_the_three.to_date)
      end

      it 'is stalled when a full set of uploads arrived recently, but not within the last 24 hours' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 3)
        all_three_completed_at = 25.hours.ago
        create_list(:grda_warehouse_upload, 3, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: all_three_completed_at)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(all_three_completed_at.to_date)
      end

      it 'is not stalled when a full set of uploads arrived within the last 24 hours' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 3)
        create_list(:grda_warehouse_upload, 3, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 23.hours.ago)

        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(nil)
      end

      it 'is stalled when fewer than the expected number of uploads arrived, even though all of them arrived within the last 24 hours' do
        create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 3)
        oldest_of_the_two = 5.hours.ago
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)
        create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: oldest_of_the_two)

        # Both uploads are recent, so recency alone would clear this data source; only the
        # count check distinguishes a partial delivery from a complete one.
        expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(oldest_of_the_two.to_date)
      end
    end

    it 'is not stalled when the import is paused, regardless of upload history' do
      create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
      create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 30.hours.ago)
      ds1.update!(import_paused: true)

      expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(nil)
    end

    it 'is not stalled when the import config is inactive, regardless of upload history' do
      create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1, active: false)
      create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 30.hours.ago)

      expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(nil)
    end

    it 'ignores uploads brought in by anyone other than the system user' do
      create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
      system_user_completed_at = 30.hours.ago
      create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: system_user_completed_at)
      create(:grda_warehouse_upload, data_source: ds1, user: user, percent_complete: 100, completed_at: 2.hours.ago)

      # The hand-uploaded file is the more recent of the two, so without the system-user
      # filter it would take rn=1 and clear the data source.
      expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(system_user_completed_at.to_date)
    end

    it 'ignores an upload that has not finished importing' do
      create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
      finished_completed_at = 30.hours.ago
      create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: finished_completed_at)
      create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 50, completed_at: 2.hours.ago)

      # The in-flight upload is the more recent of the two, so without the completed filter
      # it would take rn=1 and clear the data source.
      expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(finished_completed_at.to_date)
    end

    it "trims each data source to its own file_count instead of the batch's shared cap, when file counts differ" do
      # file_count: 1, but has 3 historical uploads - only the single most recent may count.
      single_file_ds = create(:source_data_source)
      create(:grda_warehouse_hmis_import_config, data_source: single_file_ds, file_count: 1)
      most_recent_for_single_file_ds = 30.hours.ago
      create(:grda_warehouse_upload, data_source: single_file_ds, user: User.system_user, percent_complete: 100, completed_at: most_recent_for_single_file_ds)
      create(:grda_warehouse_upload, data_source: single_file_ds, user: User.system_user, percent_complete: 100, completed_at: 50.hours.ago)
      create(:grda_warehouse_upload, data_source: single_file_ds, user: User.system_user, percent_complete: 100, completed_at: 70.hours.ago)

      # file_count: 3, sets the batch's shared row cap above 1.
      multi_file_ds = build_data_source_with_upload(file_count: 3, completed_at: 1.hour.ago)
      create(:grda_warehouse_upload, data_source: multi_file_ds, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)
      create(:grda_warehouse_upload, data_source: multi_file_ds, user: User.system_user, percent_complete: 100, completed_at: 3.hours.ago)

      result = GrdaWarehouse::DataSource.stalled_dates_by_id([single_file_ds.id, multi_file_ds.id])

      # If the shared cap (3, from multi_file_ds) leaked into single_file_ds's own calculation
      # instead of being trimmed back down to its file_count of 1, this would incorrectly equal
      # 70.hours.ago.to_date (the oldest of all three uploads) instead of the single most recent one.
      expect(result[single_file_ds.id]).to eq(most_recent_for_single_file_ds.to_date)
      expect(result[multi_file_ds.id]).to eq(nil)
    end

    it "returns each requested id's own result independently in one call, without cross-contamination" do
      stalled_ds = build_data_source_with_upload(file_count: 1, completed_at: 30.hours.ago)
      fresh_ds = build_data_source_with_upload(file_count: 1, completed_at: 2.hours.ago)

      result = GrdaWarehouse::DataSource.stalled_dates_by_id([stalled_ds.id, fresh_ds.id])

      expect(result[stalled_ds.id]).to eq(30.hours.ago.to_date)
      expect(result[fresh_ds.id]).to eq(nil)
    end

    it 'excludes a soft-deleted upload from the ranking' do
      create(:grda_warehouse_hmis_import_config, data_source: ds1, file_count: 1)
      real_completed_at = 30.hours.ago
      create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: real_completed_at)
      deleted_upload = create(:grda_warehouse_upload, data_source: ds1, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)
      deleted_upload.destroy

      # The deleted upload is more recent than the real one, so if it leaked into the
      # ranking (e.g. an `.unscoped` applied too broadly), rn=1 would pick it instead and
      # this would incorrectly return nil (not stalled) rather than the real upload's date.
      expect(GrdaWarehouse::DataSource.stalled_dates_by_id([ds1.id])[ds1.id]).to eq(real_completed_at.to_date)
    end
  end

  describe '.stalled_dates_by_id query efficiency' do
    it 'runs a bounded number of queries regardless of how many data sources are checked' do
      count_queries = lambda do |&block|
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      small_batch = Array.new(3) { build_data_source_with_upload(file_count: 1, completed_at: 30.hours.ago) }

      # Warm up one-time schema-cache/connection-setup queries so they don't confound
      # the small-vs-large comparison below.
      GrdaWarehouse::DataSource.stalled_dates_by_id(small_batch.map(&:id))

      small_queries = count_queries.call { GrdaWarehouse::DataSource.stalled_dates_by_id(small_batch.map(&:id)) }

      large_batch = small_batch + Array.new(9) { build_data_source_with_upload(file_count: 1, completed_at: 30.hours.ago) }
      large_queries = count_queries.call { GrdaWarehouse::DataSource.stalled_dates_by_id(large_batch.map(&:id)) }

      # A regression to a per-row query pattern would make large_queries scale with data
      # source count (9 more data sources here); a small constant tolerance accommodates
      # incidental variance without masking that regression.
      expect(large_queries).to be_within(2).of(small_queries)
    end
  end

  describe '.stalled_imports?' do
    around do |example|
      travel_to(import_stall_evaluated_at) { example.run }
    end

    def make_stalled(data_source)
      create(:grda_warehouse_hmis_import_config, data_source: data_source, file_count: 1)
      create(:grda_warehouse_upload, data_source: data_source, user: User.system_user, percent_complete: 100, completed_at: 30.hours.ago)
      GrdaWarehouse::ImportLog.create!(data_source: data_source, completed_at: 30.hours.ago)
    end

    def make_fresh(data_source)
      create(:grda_warehouse_hmis_import_config, data_source: data_source, file_count: 1)
      create(:grda_warehouse_upload, data_source: data_source, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)
      GrdaWarehouse::ImportLog.create!(data_source: data_source, completed_at: 2.hours.ago)
    end

    it 'returns true when a data source the user can view has a stalled import' do
      make_stalled(ds1)
      empty_collection.set_viewables({ data_sources: [ds1.id] })
      setup_access_control(user, can_view_projects, empty_collection)

      expect(GrdaWarehouse::DataSource.stalled_imports?(user)).to eq(true)
    end

    it 'returns false when the only stalled data source is outside what the user can view' do
      make_stalled(ds1)
      empty_collection.set_viewables({ data_sources: [ds2.id] })
      setup_access_control(user, can_view_projects, empty_collection)

      expect(GrdaWarehouse::DataSource.stalled_imports?(user)).to eq(false)
    end

    it 'returns false when the viewable data source has recent, non-stalled imports' do
      make_fresh(ds1)
      empty_collection.set_viewables({ data_sources: [ds1.id] })
      setup_access_control(user, can_view_projects, empty_collection)

      expect(GrdaWarehouse::DataSource.stalled_imports?(user)).to eq(false)
    end

    # The test environment uses config.cache_store = :null_store (config/environments/test.rb),
    # so Rails.cache.fetch always re-runs its block. Swap in a real store here so these examples
    # can actually observe caching behavior instead of it being a no-op.
    describe 'caching' do
      around do |example|
        original_cache_store = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
      ensure
        Rails.cache = original_cache_store
      end

      def count_queries(&block)
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      it 'reuses the cached result on a second call instead of recomputing it' do
        make_stalled(ds1)

        expect(GrdaWarehouse::DataSource.stalled_data_source_ids).to eq([ds1.id])

        queries_on_second_call = count_queries { GrdaWarehouse::DataSource.stalled_data_source_ids }

        expect(queries_on_second_call).to eq(0)
      end

      it 'shares one cached set of stalled ids across users rather than computing one per user' do
        other_user = create(:acl_user)
        other_collection = create(:collection)
        empty_collection.set_viewables({ data_sources: [ds1.id] })
        other_collection.set_viewables({ data_sources: [ds2.id] })
        setup_access_control(user, can_view_projects, empty_collection)
        setup_access_control(other_user, can_view_projects, other_collection)

        # Warms the cache while ds1 is the only stalled data source.
        make_stalled(ds1)
        expect(GrdaWarehouse::DataSource.stalled_imports?(user)).to eq(true)

        # ds2 stalls only after that warm-up, and other_user can view ds2 alone. Under a
        # per-user cache key other_user would compute a fresh set and see ds2; one shared
        # entry keeps ds2 out until the entry expires.
        make_stalled(ds2)

        expect(GrdaWarehouse::DataSource.stalled_imports?(other_user)).to eq(false)
      end
    end
  end

  describe '.stalled_imports? query efficiency' do
    it 'runs a bounded number of queries regardless of how many data sources the user can view' do
      count_queries = lambda do |&block|
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      small_batch = Array.new(3) { create(:source_data_source) }
      empty_collection.set_viewables({ data_sources: small_batch.map(&:id) })
      setup_access_control(user, can_view_projects, empty_collection)

      # Warm up one-time schema-cache/connection-setup queries so they don't confound
      # the small-vs-large comparison below.
      GrdaWarehouse::DataSource.stalled_imports?(user)
      small_queries = count_queries.call { GrdaWarehouse::DataSource.stalled_imports?(user) }

      large_batch = small_batch + Array.new(9) { create(:source_data_source) }
      empty_collection.set_viewables({ data_sources: large_batch.map(&:id) })
      large_queries = count_queries.call { GrdaWarehouse::DataSource.stalled_imports?(user) }

      expect(large_queries).to be_within(3).of(small_queries)
    end
  end

  describe '.last_import_completed_ats_by_id' do
    it 'returns the most recent completed_at per data source, keyed by id' do
      GrdaWarehouse::ImportLog.create!(data_source: ds1, completed_at: 2.days.ago)
      GrdaWarehouse::ImportLog.create!(data_source: ds1, completed_at: 1.day.ago)
      GrdaWarehouse::ImportLog.create!(data_source: ds2, completed_at: 3.days.ago)

      result = GrdaWarehouse::DataSource.last_import_completed_ats_by_id([ds1.id, ds2.id])

      expect(result[ds1.id]).to be_within(1.second).of(1.day.ago)
      expect(result[ds2.id]).to be_within(1.second).of(3.days.ago)
    end

    it 'omits an id with no import logs at all, so callers can tell "never imported" apart from "imported long ago"' do
      result = GrdaWarehouse::DataSource.last_import_completed_ats_by_id([ds1.id])

      expect(result).not_to have_key(ds1.id)
    end
  end

  describe '.client_counts_by_id' do
    it "matches each data source's own #client_count" do
      create_list(:hud_client, 2, data_source_id: ds1.id)
      create(:hud_client, data_source_id: ds2.id)

      result = GrdaWarehouse::DataSource.client_counts_by_id([ds1.id, ds2.id])

      expect(result[ds1.id]).to eq(ds1.client_count)
      expect(result[ds2.id]).to eq(ds2.client_count)
      expect(result[ds1.id]).to eq(2)
      expect(result[ds2.id]).to eq(1)
    end

    it 'defaults to 0 for a data source with no clients, rather than omitting its key' do
      result = GrdaWarehouse::DataSource.client_counts_by_id([ds1.id])

      expect(result[ds1.id]).to eq(0)
    end
  end

  describe '.project_counts_by_id' do
    it "matches each data source's own #project_count" do
      result = GrdaWarehouse::DataSource.project_counts_by_id([ds1.id, ds2.id])

      # ds1 has p1-p4, ds2 has p5-p8 (see the fixture hierarchy at the top of this file).
      expect(result[ds1.id]).to eq(ds1.project_count)
      expect(result[ds2.id]).to eq(ds2.project_count)
      expect(result[ds1.id]).to eq(4)
      expect(result[ds2.id]).to eq(4)
    end

    it 'defaults to 0 for a data source with no projects, rather than omitting its key' do
      empty_ds = create(:source_data_source)

      result = GrdaWarehouse::DataSource.project_counts_by_id([empty_ds.id])

      expect(result[empty_ds.id]).to eq(0)
    end
  end

  describe '.unprocessed_enrollment_counts_by_id' do
    def create_resolvable_enrollment(data_source:, project:, processed_as:)
      source_client = create(:hud_client, data_source: data_source)
      destination_client = source_client.dup
      destination_client.data_source = create(:destination_data_source)
      destination_client.save!
      create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
      create(:hud_enrollment, data_source: data_source, project: project, client: source_client, processed_as: processed_as)
    end

    it "matches each data source's own #unprocessed_enrollment_count" do
      create_resolvable_enrollment(data_source: ds1, project: p1, processed_as: nil)
      create_resolvable_enrollment(data_source: ds1, project: p1, processed_as: { 'a' => 1 })

      result = GrdaWarehouse::DataSource.unprocessed_enrollment_counts_by_id([ds1.id, ds2.id])

      expect(result[ds1.id]).to eq(ds1.unprocessed_enrollment_count)
      expect(result[ds1.id]).to eq(1)
      expect(result[ds2.id]).to eq(0)
    end

    it 'defaults to 0 for a data source with no unprocessed enrollments, rather than omitting its key' do
      result = GrdaWarehouse::DataSource.unprocessed_enrollment_counts_by_id([ds1.id])

      expect(result[ds1.id]).to eq(0)
    end
  end

  describe 'importable?' do
    let!(:vendor_ds) { create(:source_data_source) }
    let!(:authoritative_ds) { create(:authoritative_data_source) }

    it 'is importable for non-authoritative sources when imports are enabled' do
      expect(vendor_ds.importable?).to be true
      expect(model.importable).to include(vendor_ds)
    end

    it 'is not importable when disable_imports is true' do
      vendor_ds.update!(disable_imports: true)
      expect(vendor_ds.importable?).to be false
    end

    it 'is not importable for authoritative non-HMIS sources' do
      expect(authoritative_ds.importable?).to be false
    end

    it 'is importable for OP HMIS sources when imports are enabled' do
      hmis_ds = create(:source_data_source, hmis: 'hmis.example.test', authoritative: true)
      expect(hmis_ds.importable?).to be true
    end

    it 'is not importable for OP HMIS sources when disable_imports is true' do
      hmis_ds = create(:source_data_source, hmis: 'hmis.example.test', authoritative: true, disable_imports: true)
      expect(hmis_ds.importable?).to be false
    end
  end

  describe '#importable_by?' do
    let!(:upload_role) { create :role, name: 'upload role', can_upload_hud_zips: true }
    let!(:upload_user) { create :acl_user }
    let!(:vendor_ds) { create :source_data_source }

    before do
      Collection.maintain_system_groups
      setup_access_control(upload_user, upload_role, Collection.system_collection(:data_sources))
    end

    it 'returns true when the source is importable and the user can upload' do
      expect(vendor_ds.importable_by?(upload_user)).to be true
    end

    it 'returns false when imports are disabled' do
      vendor_ds.update!(disable_imports: true)
      expect(vendor_ds.importable_by?(upload_user)).to be false
    end

    it 'returns false when the user lacks upload permission' do
      edit_only_role = create(:role, name: 'edit only role', can_edit_data_sources: true)
      user = create(:acl_user)
      setup_access_control(user, edit_only_role, Collection.system_collection(:data_sources))
      expect(vendor_ds.importable_by?(user)).to be false
    end

    it 'returns false when the user lacks data source access' do
      user = create(:acl_user)
      setup_access_control(user, upload_role, create(:collection))
      expect(vendor_ds.importable_by?(user)).to be false
    end
  end

  describe '#hmis_login_url' do
    let!(:hmis_ds) { create(:source_data_source, hmis: 'hmis.example.test', authoritative: true) }

    it 'returns nil for a data source with no HMIS hostname' do
      expect(ds1.hmis_login_url).to be_nil
    end

    it 'points at the HMIS host', :devise_only do
      expect(hmis_ds.hmis_login_url).to eq('https://hmis.example.test/')
    end

    it "routes through HMIS's own oauth2-proxy sign-in endpoint with the user's connector_id, so Dex skips its connector picker", :jwt_only do
      user.update_column(:last_connector_id, 'keycloak')

      expect(hmis_ds.hmis_login_url(user: user)).to eq('https://hmis.example.test/oauth2/sign_in?connector_id=keycloak&rd=%2F')
    end

    it 'is unaffected by connector_id under Devise', :devise_only do
      user.update_column(:last_connector_id, 'keycloak')

      expect(hmis_ds.hmis_login_url(user: user)).to eq('https://hmis.example.test/')
    end
  end

  describe '#hmis_url_for' do
    let!(:hmis_ds) { create(:source_data_source, hmis: 'hmis.example.test', authoritative: true) }
    let(:client) { create(:hud_client, data_source: hmis_ds) }

    before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

    it 'points at the deep-linked path when no user is given' do
      expect(hmis_ds.hmis_url_for(client)).to eq("https://hmis.example.test/client/#{client.id}")
    end

    it "routes through HMIS's own oauth2-proxy sign-in endpoint with the user's connector_id, so Dex skips its connector picker", :jwt_only do
      allow(user).to receive(:related_hmis_user).and_return(nil)
      user.update_column(:last_connector_id, 'keycloak')

      expect(hmis_ds.hmis_url_for(client, user: user)).
        to eq("https://hmis.example.test/oauth2/sign_in?connector_id=keycloak&rd=%2Fclient%2F#{client.id}")
    end

    it 'is unaffected by connector_id under Devise', :devise_only do
      allow(user).to receive(:related_hmis_user).and_return(nil)
      user.update_column(:last_connector_id, 'keycloak')

      expect(hmis_ds.hmis_url_for(client, user: user)).to eq("https://hmis.example.test/client/#{client.id}")
    end
  end

  describe 'hmis hostnames' do
    it 'returns configured hostnames from env' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HMIS_HOSTNAME', '').and_return('hmis-a.example.test,hmis-b.example.test')
      expect(HmisEnforcement.configured_hmis_hostnames).to eq(['hmis-a.example.test', 'hmis-b.example.test'])
    end

    it 'returns available hostnames excluding assigned data sources' do
      allow(HmisEnforcement).to receive(:configured_hmis_hostnames).and_return(['hmis-a.example.test', 'hmis-b.example.test'])
      create(:source_data_source, hmis: 'hmis-a.example.test', authoritative: true)
      expect(model.available_hmis_hostnames).to eq(['hmis-b.example.test'])
    end

    it 'rejects hmis hostnames not in env' do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(HmisEnforcement).to receive(:configured_hmis_hostnames).and_return(['hmis-a.example.test'])
      ds = build(:source_data_source, hmis: 'other.example.test', authoritative: true)
      expect(ds).not_to be_valid
      expect(ds.errors[:hmis]).to be_present
    end

    it 'rejects duplicate hmis hostnames' do
      create(:source_data_source, hmis: 'hmis-a.example.test', authoritative: true)
      ds = build(:source_data_source, hmis: 'hmis-a.example.test', authoritative: true)
      expect(ds).not_to be_valid
      expect(ds.errors[:hmis]).to include('has already been taken')
    end

    it 'rejects changing hmis once set' do
      ds = create(:source_data_source, hmis: 'hmis-a.example.test', authoritative: true)
      ds.hmis = 'hmis-b.example.test'
      expect(ds).not_to be_valid
      expect(ds.errors[:hmis]).to include('cannot be changed once set')
    end

    it 'rejects clearing hmis once set' do
      ds = create(:source_data_source, hmis: 'hmis-a.example.test', authoritative: true)
      ds.hmis = nil
      expect(ds).not_to be_valid
      expect(ds.errors[:hmis]).to include('cannot be changed once set')
    end
  end

  describe 'OP HMIS defaults' do
    it 'enforces fixed attribute defaults when hmis is set' do
      ds = create(:source_data_source, hmis: 'hmis-a.example.test', authoritative_type: :youth, service_scannable: true)
      expect(ds.authoritative).to be true
      expect(ds.authoritative_type).to be_nil
      expect(ds.source_type).to be_nil
      expect(ds.munged_personal_id).to be false
      expect(ds.after_create_path).to be_nil
      expect(ds.service_scannable).to be false
    end
  end

  describe '#require_coc_choice?' do
    let!(:ds) { create(:source_data_source) }
    let!(:org) { create(:hud_organization, data_source_id: ds.id) }
    let(:all_projects) { GrdaWarehouse::Hud::Project.all }

    def add_projects_with_coc(coc_code, count)
      create_list(:hud_project, count, data_source_id: ds.id, OrganizationID: org.OrganizationID).each do |project|
        create(:hud_project_coc, data_source_id: ds.id, ProjectID: project.ProjectID, CoCCode: coc_code)
      end
    end

    it 'does not require a choice when one CoC has exactly the dominance threshold share' do
      add_projects_with_coc('XX-500', 3)
      add_projects_with_coc('XX-502', 1)
      expect(ds.require_coc_choice?(all_projects)).to eq(false)
    end

    it 'requires a choice when just under the dominance threshold' do
      add_projects_with_coc('XX-500', 2)
      add_projects_with_coc('XX-502', 1)
      expect(ds.require_coc_choice?(all_projects)).to eq(true)
    end

    it 'requires a choice once project count reaches the size threshold, even when fully concentrated' do
      stub_const('GrdaWarehouse::DataSource::SMALL_ENOUGH_PROJECT_COUNT', 3)
      add_projects_with_coc('XX-500', 3)
      expect(ds.require_coc_choice?(all_projects)).to eq(true)
    end

    it 'does not require a choice just under the size threshold when fully concentrated' do
      stub_const('GrdaWarehouse::DataSource::SMALL_ENOUGH_PROJECT_COUNT', 3)
      add_projects_with_coc('XX-500', 2)
      expect(ds.require_coc_choice?(all_projects)).to eq(false)
    end

    it 'does not require a choice when there is no CoC data at all' do
      create_list(:hud_project, 3, data_source_id: ds.id, OrganizationID: org.OrganizationID)
      expect(ds.require_coc_choice?(all_projects)).to eq(false)
    end

    it 'only counts CoC data for projects included in the given project scope' do
      add_projects_with_coc('XX-500', 2)
      add_projects_with_coc('XX-502', 1)
      # Unscoped: 2/3 =~ 66.7% dominance, under the 75% threshold, so a choice is required.
      expect(ds.require_coc_choice?(all_projects)).to eq(true)

      visible_project_ids = GrdaWarehouse::Hud::ProjectCoc.where(data_source_id: ds.id, CoCCode: 'XX-500').pluck(:ProjectID)
      restricted_scope = GrdaWarehouse::Hud::Project.where(data_source_id: ds.id, ProjectID: visible_project_ids)
      # Restricted to only the projects with a visible CoC: fully concentrated, so no choice is needed.
      expect(ds.require_coc_choice?(restricted_scope)).to eq(false)
    end

    it 'treats nil, empty, and whitespace-only CoC codes as a single dominance bucket' do
      add_projects_with_coc('XX-500', 1)
      add_projects_with_coc(nil, 1)
      add_projects_with_coc('', 1)
      add_projects_with_coc('   ', 1)
      # Grouped as one "unknown" bucket: 3/4 = 75%, meeting the threshold, so no choice is needed.
      # If nil/''/'   ' were instead counted as three separate one-project buckets, the largest
      # bucket would be XX-500 with 1/4 = 25%, well under the threshold, and a choice would wrongly
      # be required.
      expect(ds.require_coc_choice?(all_projects)).to eq(false)
    end
  end

  describe '#coc_summaries' do
    let!(:ds) { create(:source_data_source) }
    let!(:org1) { create(:hud_organization, data_source_id: ds.id) }
    let!(:org2) { create(:hud_organization, data_source_id: ds.id) }
    let(:all_projects) { GrdaWarehouse::Hud::Project.all }

    def add_project_with_coc(coc_code, organization:, site_count: 1)
      project = create(:hud_project, data_source_id: ds.id, OrganizationID: organization.OrganizationID)
      create_list(:hud_project_coc, site_count, data_source_id: ds.id, ProjectID: project.ProjectID, CoCCode: coc_code)
      project
    end

    it 'summarizes distinct project and organization counts per CoC, sorted by code with unknown last' do
      # multi_site_project has two ProjectCoC rows for the same CoC (HUD allows multiple
      # site records per project/CoC) - it must still only count once toward project_count.
      multi_site_project = add_project_with_coc('XX-501', organization: org1, site_count: 2)
      add_project_with_coc('XX-501', organization: org1)
      add_project_with_coc('XX-500', organization: org2)
      add_project_with_coc(nil, organization: org2)

      summaries = ds.coc_summaries(all_projects)

      expect(summaries).to eq([
                                { code: 'XX-500', name: HudHelper.util.coc_name('XX-500'), project_count: 1, org_count: 1 },
                                { code: 'XX-501', name: HudHelper.util.coc_name('XX-501'), project_count: 2, org_count: 1 },
                                { code: 'unknown', name: Translation.translate('Unknown CoC'), project_count: 1, org_count: 1 },
                              ])
      expect(GrdaWarehouse::Hud::ProjectCoc.where(ProjectID: multi_site_project.ProjectID).count).to eq(2)
    end

    it 'treats nil, empty, and whitespace-only CoC codes as a single unknown bucket' do
      add_project_with_coc(nil, organization: org1)
      add_project_with_coc('', organization: org1)
      add_project_with_coc('   ', organization: org2)

      summaries = ds.coc_summaries(all_projects)

      expect(summaries).to contain_exactly(
        { code: 'unknown', name: Translation.translate('Unknown CoC'), project_count: 3, org_count: 2 },
      )
    end

    it 'only counts projects included in the given project scope' do
      add_project_with_coc('XX-500', organization: org1)
      excluded_project = add_project_with_coc('XX-501', organization: org2)

      restricted_scope = GrdaWarehouse::Hud::Project.where.not(ProjectID: excluded_project.ProjectID)

      expect(ds.coc_summaries(restricted_scope).map { |s| s[:code] }).to contain_exactly('XX-500')
    end
  end

  describe '#users_with_view_access' do
    # A can_view_clients grant only counts if it actually reaches this data source.
    # Legacy users (using_acls? false) reach it via AccessGroup#add_viewable; ACL users
    # (using_acls? true) reach it via a Collection whose set_viewables covers this data
    # source (directly or via its organizations/projects/etc) - a role granting
    # can_view_clients through some OTHER, unrelated collection must NOT count, since
    # that collection was never given access to this data source.
    let!(:ds) { create(:source_data_source) }
    # Distinct names matter here: setup_access_control keys its UserGroup lookup by
    # "#{role.name} x #{collection.name}" - two same-named roles sharing a collection
    # would collapse into one UserGroup, and its members would inherit both roles.
    let!(:viewer_role) { create(:role, name: 'viewer', can_view_clients: true) }
    let!(:non_viewing_role) { create(:role, name: 'non_viewer', can_view_clients: false) }
    let!(:legacy_viewer) { create(:user) }
    let!(:legacy_wrong_role_user) { create(:user) }
    let!(:acl_viewer) { create(:acl_user) }
    let!(:acl_wrong_collection_user) { create(:acl_user) }
    let!(:acl_wrong_role_user) { create(:acl_user) }

    before do
      legacy_viewer.add_viewable(ds)
      legacy_viewer.legacy_roles << viewer_role

      legacy_wrong_role_user.add_viewable(ds)
      legacy_wrong_role_user.legacy_roles << non_viewing_role

      covering_collection = create(:collection)
      covering_collection.set_viewables({ data_sources: [ds.id] })
      setup_access_control(acl_viewer, viewer_role, covering_collection)

      unrelated_collection = create(:collection)
      unrelated_collection.set_viewables({ data_sources: [create(:source_data_source).id] })
      setup_access_control(acl_wrong_collection_user, viewer_role, unrelated_collection)

      setup_access_control(acl_wrong_role_user, non_viewing_role, covering_collection)
    end

    it 'includes legacy and ACL users whose can_view_clients grant actually reaches this data source' do
      expect(ds.users_with_view_access).to contain_exactly(legacy_viewer, acl_viewer)
    end
  end

  describe '#pre_process_hooks' do
    it 'defaults pre_process_hooks to an empty hash' do
      data_source = create(:source_data_source)
      expect(data_source.pre_process_hooks).to eq({})
    end
  end

  describe 'PaperTrail' do
    it 'creates a version on update' do
      PaperTrailHelper.with_paper_trail do
        ds = create(:source_data_source)
        expect do
          ds.update!(hmis: 'tenant.example.test')
        end.to change(ds.versions, :count).by(1)
        expect(ds.versions.last.changeset.keys).to include('hmis')
      end
    end

    it 'does not create a version for last_imported_at changes' do
      PaperTrailHelper.with_paper_trail do
        ds = create(:source_data_source)
        expect do
          ds.update!(last_imported_at: Time.current)
        end.to_not change(ds.versions, :count)
      end
    end
  end
end
