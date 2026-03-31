###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Ensures the canonical HMIS test data source exists and loads JSON form definitions (see HmisUtil::JsonForms).
#
# When used alongside `include_context 'hmis base setup'`, this context's `let(:ds1)` often overrides the
# factory-backed `let!(:ds1)` from base setup
RSpec.shared_context 'hmis json forms seed', shared_context: :metadata do
  before(:all) do
    ds = GrdaWarehouse::DataSource.find_or_create_by!(
      hmis: GraphqlHelpers::HMIS_HOSTNAME,
      name: 'HMIS',
      short_name: 'HMIS',
      authoritative: true,
    )
    HmisUtil::JsonForms.seed_all(data_source_id: ds.id)
  end

  let(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: GraphqlHelpers::HMIS_HOSTNAME) }
end
