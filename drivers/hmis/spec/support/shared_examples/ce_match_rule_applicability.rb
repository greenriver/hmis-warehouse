###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared context for CE match rule specs that test applicability config (project types and funders).
# Expects `p1` to be defined (typically via 'hmis base setup').
RSpec.shared_context 'ce match rule applicability helpers' do
  let(:project_type) { p1.project_type }
  let(:project_type_key) { Types::HmisSchema::Enums::ProjectType.key_for(project_type) }
  let(:funder_code) { HudHelper.util.funding_source('HUD: CoC - Rapid Re-Housing', true, raise_on_missing: true) }
  let(:funder_key) { Types::HmisSchema::Enums::Hud::FundingSource.key_for(funder_code) }
end
