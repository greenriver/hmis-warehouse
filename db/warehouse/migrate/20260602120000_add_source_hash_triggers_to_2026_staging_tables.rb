# frozen_string_literal: true

# Compute `source_hash` in PostgreSQL via a BEFORE INSERT OR UPDATE trigger on
# each 2026 importer staging table, replacing the per-row Ruby
# `klass.new(...).calculate_source_hash` in the pre_process hot loop.
#
# See HmisCsvTwentyTwentySix::SourceHash::TriggerGenerator for the SQL generation
# and db/warehouse/migrate/20241206145315_replace_rules_with_triggers.rb for precedent.
class AddSourceHashTriggersTo2026StagingTables < ActiveRecord::Migration[7.2]
  def up
    generator.staging_classes.each do |klass|
      safety_assured { execute generator.function_sql(klass) }
      safety_assured { execute generator.create_trigger_sql(klass) }
    end
  end

  def down
    generator.staging_classes.each do |klass|
      safety_assured { execute generator.drop_trigger_sql(klass) }
      safety_assured { execute generator.drop_function_sql(klass) }
    end
  end

  private

  def generator
    HmisCsvTwentyTwentySix::SourceHash::TriggerGenerator
  end
end
