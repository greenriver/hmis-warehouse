class AddInternalSystemsPart2 < ActiveRecord::Migration[6.1]
  def up
    require_relative '../../seed_maker'
    SeedMaker.new.populate_internal_system_choices
  end
end
