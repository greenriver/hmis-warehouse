# frozen_string_literal: true

# Compute `source_hash` in PostgreSQL via a BEFORE INSERT OR UPDATE trigger on
# each 2026 importer staging table, replacing the per-row Ruby
# `klass.new(...).calculate_source_hash` in the pre_process hot loop.
#
# Function bodies are the committed canonical fx files in db/functions/, loaded
# via create_function. Triggers are attached with raw `execute` (strong_migrations
# requires safety_assured for trigger DDL). See
# HmisCsvTwentyTwentySix::SourceHash::TriggerGenerator and
# db/warehouse/migrate/20241206145315_replace_rules_with_triggers.rb for precedent.
class AddSourceHashTriggersTo2026StagingTables < ActiveRecord::Migration[7.2]
  def up
    generator.staging_classes.each do |klass|
      create_function generator.function_name(klass)
      safety_assured { execute generator.create_trigger_sql(klass) }
    end
  end

  def down
    generator.staging_classes.each do |klass|
      safety_assured { execute generator.drop_trigger_sql(klass) }
      drop_function generator.function_name(klass)
    end
  end

  private

  def generator
    HmisCsvTwentyTwentySix::SourceHash::TriggerGenerator
  end
end
