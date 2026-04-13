###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Ensures the canonical HMIS test data source exists, and loads:
# - service types and categories
# - JSON form definitions
# - system form instances
#
# This is a performance improvement that helps us avoid creating these forms in fixtures,
# which would run per-test and be expensive.
#
# Relationship to 'hmis base setup':
# - 'hmis base setup' defines `let!(:ds1) { create(:hmis_primary_data_source) }`, a fresh factory data source per example group.
# - This context defines `let(:ds1)` to resolve the canonical HMIS data source row created in `before(:all)` (same hostname as GraphqlHelpers::HMIS_HOSTNAME).
# - When both contexts are included in one group, include 'hmis base setup' first, then 'hmis json forms seed', so this `let(:ds1)` wins and every reference to `ds1` in the group uses the seeded data source (JSON forms, HUD service types/categories, etc.) instead of attempting to create a new DS with the same hostname.
RSpec.shared_context 'hmis json forms seed', shared_context: :metadata do
  before(:all) do
    ds = GrdaWarehouse::DataSource.find_or_create_by!(hmis: GraphqlHelpers::HMIS_HOSTNAME) do |d|
      d.name = 'HMIS'
      d.short_name = 'HMIS'
      d.authoritative = true
    end
    HmisUtil::ServiceTypes.seed_hud_service_types(ds.id)
    HmisUtil::JsonForms.seed_all(data_source_id: ds.id)
  end

  # Resolves the same row as `before(:all)`
  let(:ds1) { GrdaWarehouse::DataSource.hmis.find_by!(hmis: GraphqlHelpers::HMIS_HOSTNAME) }

  after(:all) do
    # Clean up the data source so that other tests can create their own ds unimpeded
    ds = GrdaWarehouse::DataSource.find_by!(hmis: GraphqlHelpers::HMIS_HOSTNAME)
    # TODO(#6691) - delete forms and instances by data source
    Hmis::Form::Instance.delete_all
    Hmis::Form::Definition.delete_all # bypass the before_destroy callback
    Hmis::Hud::CustomDataElementDefinition.where(data_source: ds).delete_all
    Hmis::Hud::CustomDataElement.where(data_source: ds).delete_all
    Hmis::Hud::CustomServiceCategory.where(data_source: ds).delete_all
    Hmis::Hud::CustomServiceType.where(data_source: ds).delete_all
    ds.destroy!
  end
end
