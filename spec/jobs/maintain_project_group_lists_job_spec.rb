###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaintainProjectGroupListsJob, type: :job do
  describe '#perform' do
    it 'maintains both warehouse and HMIS project group lists when HMIS is enabled' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      expect(GrdaWarehouse::ProjectGroup).to receive(:maintain_project_lists!)
      expect(Hmis::ProjectGroup).to receive(:maintain_project_lists!)
      described_class.new.perform
    end

    it 'skips HMIS project group lists when HMIS is not enabled' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)
      expect(GrdaWarehouse::ProjectGroup).to receive(:maintain_project_lists!)
      expect(Hmis::ProjectGroup).not_to receive(:maintain_project_lists!)
      described_class.new.perform
    end
  end

  describe 'advisory lock' do
    it 'rewrites no project group lists when a second copy runs while the lock is held' do
      allow(GrdaWarehouseBase).to receive(:with_advisory_lock).
        with(MaintainProjectGroupListsJob::LOCK_NAME, timeout_seconds: 0).and_return(false)

      expect(GrdaWarehouse::ProjectGroup).not_to receive(:maintain_project_lists!)
      expect(Hmis::ProjectGroup).not_to receive(:maintain_project_lists!)
      described_class.new.perform
    end
  end
end
