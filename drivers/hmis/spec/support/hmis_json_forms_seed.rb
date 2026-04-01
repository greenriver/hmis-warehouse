###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Ensures the canonical HMIS test data source exists and loads JSON form definitions (see HmisUtil::JsonForms).
#
# When used alongside 'hmis base setup', this context's `let(:ds1)` overrides the factory-based `ds1`.
RSpec.shared_context 'hmis json forms seed', shared_context: :metadata do
  # Seed forms in a before(:all) block to improve performance
  before(:all) do # todo @martha - would be faster to do before(:suite) but this needs to be an rspec config. explore later
    ds = GrdaWarehouse::DataSource.find_or_create_by!(
      hmis: GraphqlHelpers::HMIS_HOSTNAME,
      name: 'HMIS',
      short_name: 'HMIS',
      authoritative: true,
    )
    HmisUtil::JsonForms.seed_all(data_source_id: ds.id)
  end

  # Use find_by! since we already created ds1 in before_all
  let(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: GraphqlHelpers::HMIS_HOSTNAME) }

  after(:all) do
    # Clean up the data source so that other tests can create their own ds unimpeded
    data_source = GrdaWarehouse::DataSource.find_by(hmis: GraphqlHelpers::HMIS_HOSTNAME)
    Hmis::Form::Definition.where(data_source: data_source).destroy_all
    Hmis::Form::Instance.where(data_source: data_source).destroy_all
    data_source.destroy!
  end
end
