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
# Caution: before(all)
#
#    - [ ] Caution about before(:all) running for each describe block. Mention the tradeoff
#
# When used alongside 'hmis base setup', this context's `let(:ds1)` overrides the factory-based `ds1`.
RSpec.shared_context 'hmis json forms seed', shared_context: :metadata do
  # Seed forms in a before(:all) block to improve performance
  before(:all) do
    ds = GrdaWarehouse::DataSource.find_or_create_by!(
      hmis: GraphqlHelpers::HMIS_HOSTNAME,
      name: 'HMIS',
      short_name: 'HMIS',
      authoritative: true,
    )
    HmisUtil::ServiceTypes.seed_hud_service_types(ds.id)
    HmisUtil::JsonForms.seed_all(data_source_id: ds.id)
  end

  # Use find_by! since we already created ds1 in before_all
  let(:ds1) { GrdaWarehouse::DataSource.hmis.find_by!(hmis: GraphqlHelpers::HMIS_HOSTNAME) }

  after(:all) do
    # Clean up the data source so that other tests can create their own ds unimpeded
    ds = GrdaWarehouse::DataSource.find_by!(hmis: GraphqlHelpers::HMIS_HOSTNAME)
    # TODO(#6691) - destroy forms by data source
    Hmis::Form::Definition.destroy_all
    Hmis::Form::Instance.destroy_all
    Hmis::Hud::CustomDataElementDefinition.where(data_source: ds).destroy_all
    Hmis::Hud::CustomDataElement.where(data_source: ds).destroy_all
    Hmis::Hud::CustomServiceCategory.where(data_source: ds).destroy_all
    Hmis::Hud::CustomServiceType.where(data_source: ds).destroy_all
    ds.destroy!
  end
end
