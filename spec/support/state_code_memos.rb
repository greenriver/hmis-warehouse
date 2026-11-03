###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Config.relevant_state_codes and each shape class's my_fips_state_codes memoize on the class, so a
# value one example stubs or reads before its fixtures exist would otherwise leak into later examples.
RSpec.configure do |config|
  config.before do
    GrdaWarehouse::Config.instance_variable_set(:@relevant_state_codes, nil)
    [
      GrdaWarehouse::Shape::BlockGroup,
      GrdaWarehouse::Shape::Coc,
      GrdaWarehouse::Shape::County,
      GrdaWarehouse::Shape::Place,
      GrdaWarehouse::Shape::State,
      GrdaWarehouse::Shape::Town,
      GrdaWarehouse::Shape::ZipCode,
    ].each { |shape| shape.instance_variable_set(:@my_fips_state_codes, nil) }
  end
end
