###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GrdaWarehouseBase.disable_nestloop', type: :model do
  # Characterization coverage for the planner guard: the HMIS CSV importer
  # (issue 9211) relies on this wrapping only its block — set inside, restored
  # after, restored on error — now that it is applied narrowly around
  # individual statements instead of whole phases.
  def current_setting
    GrdaWarehouseBase.connection.select_value('SHOW enable_nestloop')
  end

  it 'disables nested loops inside the block and restores the prior value after' do
    expect(current_setting).to eq('on')

    inside = nil
    GrdaWarehouseBase.disable_nestloop do
      inside = current_setting
    end

    expect(inside).to eq('off')
    expect(current_setting).to eq('on')
  end

  it 'restores the prior value when the block raises' do
    expect do
      GrdaWarehouseBase.disable_nestloop { raise ArgumentError, 'boom' }
    end.to raise_error(ArgumentError, 'boom')

    expect(current_setting).to eq('on')
  end

  it 'supports nesting without losing the outer disabled state' do
    inside_nested = nil
    after_nested = nil
    GrdaWarehouseBase.disable_nestloop do
      GrdaWarehouseBase.disable_nestloop do
        inside_nested = current_setting
      end
      after_nested = current_setting
    end

    expect(inside_nested).to eq('off')
    expect(after_nested).to eq('off')
    expect(current_setting).to eq('on')
  end
end
