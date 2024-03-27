###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe HmisDataCleanup::Util, type: :model do
  let!(:hmis_ds) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: hmis_ds }
  let!(:p1) { create :hmis_hud_project, data_source: hmis_ds, organization: o1 }
  let!(:e1) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds, project: p1 }
  let!(:e2) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds, project: p1 }
  let!(:e3) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds }
  let!(:e4) { create :hmis_hud_enrollment, DateCreated: 5.years.ago, DateUpdated: 5.years.ago, data_source: hmis_ds }

  before(:all) do
    # create cruft in other data sources
    [:destination_data_source, :source_data_source].each do |ds_factory|
      ds = create(ds_factory)
      proj = create(:hud_project, data_source_id: ds.id)
      client = create(:grda_warehouse_hud_client, data_source_id: ds.id)
      5.times do
        create(:grda_warehouse_hud_enrollment, data_source_id: ds.id, client: client, project: proj, DateCreated: 5.years.ago, DateUpdated: 5.years.ago)
      end
    end
  end

  def expect_leaves_non_hmis_data_alone(&block)
    expect do
      yield block
    end.to change(GrdaWarehouse::Hud::Enrollment, :count).by(0).
      and change(GrdaWarehouse::Version, :count).by(0).
      and change(GrdaWarehouse::Hud::Enrollment.where(DateUpdated: 5.minutes.ago..), :count).by(0)
  end

  context 'clear_enrollment_export_ids' do
    it 'works' do
      GrdaWarehouse::Hud::Enrollment.update_all(ExportID: 'XYZ')

      old_timestamp = e1.date_updated
      HmisDataCleanup::Util.clear_enrollment_export_ids!

      expect(e1.date_updated).to eq(old_timestamp)
      expect(GrdaWarehouse::Hud::Enrollment.where(data_source: hmis_ds).where.not(ExportID: nil).exists?).to be false
      expect(GrdaWarehouse::Hud::Enrollment.where.not(data_source: hmis_ds).where(ExportID: nil).exists?).to be false
    end

    it 'leaves no trace' do
      GrdaWarehouse::Hud::Enrollment.update_all(ExportID: 'XYZ')
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.clear_enrollment_export_ids!
      end
    end
  end

  context 'all utilities' do
    it 'leave non-HMIS data untouched' do
      expect_leaves_non_hmis_data_alone do
        HmisDataCleanup::Util.update_all_enrollment_cocs!('KY-100')
      end
    end
  end
  # TODO test assign_missing_household_ids!
  # TODO test make_sole_member_hoh!!
  # TODO test all others
end
