# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Simple struct to describe a UnitGroup's candidate pool assignment change
  PoolChange = Struct.new(:unit_group, :old_pool, :new_pool, keyword_init: true)
end
