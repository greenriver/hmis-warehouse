###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared helpers for HmisDataCleanup specs that mutate HMIS HUD records.
# Requires the including spec to define `hmis_ds`.
RSpec.shared_context 'hmis data cleanup spec helpers' do
  let!(:other_dest_ds) { create(:destination_data_source) }
  let!(:other_source_ds) { create(:source_data_source) }
  let!(:other_enrollments) do
    other_enrollments = []
    # create cruft in other data sources
    [other_dest_ds, other_source_ds].each do |ds|
      proj = create(:hud_project, data_source_id: ds.id)
      client = create(:grda_warehouse_hud_client, data_source_id: ds.id)
      5.times do
        other_enrollments << create(:grda_warehouse_hud_enrollment, data_source_id: ds.id, client: client, project: proj, DateCreated: 1.year.ago, DateUpdated: 1.year.ago)
      end
    end
    other_enrollments
  end

  let(:hmis_hud_classes) { Hmis::Hud::Project.hmis_classes.excluding(Hmis::Hud::Export) }

  def expect_leaves_non_hmis_data_alone(&block)
    expect do
      yield block
    end.to not_change(GrdaWarehouse::Version, :count).
      # Data in non-HMIS data sources should not be changed
      and(
        not_change do
          hmis_hud_classes.flat_map do |scope|
            scope.order(:id).with_deleted.where.not(data_source: hmis_ds).map(&:attributes)
          end
        end,
      ).
      # DateUpdated should not be changed on any records in any data source
      and(
        not_change do
          hmis_hud_classes.map do |scope|
            [
              scope.name.demodulize,
              scope.where(DateUpdated: 5.minutes.ago..).count,
            ]
          end.to_h
        end,
      )
  end
end
