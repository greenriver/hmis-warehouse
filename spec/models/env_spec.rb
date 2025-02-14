###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'fiddle'
RSpec.describe 'Jemalloc Integration', type: :system do
  it 'verifies that jemalloc is in use' do
    maps_file = '/proc/self/maps'
    maps_content = File.read(maps_file)
    jemalloc_loaded = maps_content.include?('libjemalloc.so.2')

    expect(jemalloc_loaded).to be true
  end
end
