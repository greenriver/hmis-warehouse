###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'audit:yaml_permitted_classes' do
  let(:rake) { Rake::Application.new }
  let(:task_name) { 'audit:yaml_permitted_classes' }

  before do
    Rake.application = rake
    Rake::Task.define_task(:environment)
    Rake.load_rakefile(Rails.root.join('lib/tasks/audit_yaml_permitted_classes.rake'))
  end

  after do
    rake[task_name].reenable
  end

  it 'reports OK for a column containing only permitted classes' do
    data_source = create(:grda_warehouse_data_source)
    GrdaWarehouse::ImportLog.create!(data_source: data_source, import_errors: [{ 'message' => 'fine' }])

    expect { Rake::Task[task_name].invoke }.to output(/GrdaWarehouse::ImportLog#import_errors: checked \d+ row\(s\) - OK/).to_stdout
  end

  it 'reports the offending class name for a row containing a disallowed class' do
    data_source = create(:grda_warehouse_data_source)
    log = GrdaWarehouse::ImportLog.create!(data_source: data_source, import_errors: [{ 'message' => 'fine' }])
    malicious_yaml = "--- !ruby/object:Gem::Requirement\nrequirements: []\n"
    # GrdaWarehouse::ImportLog lives on the warehouse-db connection, not ActiveRecord::Base's
    # default (app-db) connection — use the model's own connection for the raw UPDATE.
    GrdaWarehouse::ImportLog.connection.execute(
      "UPDATE import_logs SET import_errors = #{GrdaWarehouse::ImportLog.connection.quote(malicious_yaml)} WHERE id = #{log.id}",
    )

    expect { Rake::Task[task_name].invoke }.to output(
      /GrdaWarehouse::ImportLog#import_errors: checked \d+ row\(s\) - NEEDS ATTENTION\n\s+Gem::Requirement \(1 row\(s\)\)/,
    ).to_stdout
  end

  it 'reports OK for Cohort#column_state using its own per-column extra permitted classes' do
    cohort = create(:cohort)
    cohort.class.connection.execute(
      "UPDATE cohorts SET column_state = #{cohort.class.connection.quote(YAML.dump([CohortColumns::LastName.new]))} WHERE id = #{cohort.id}",
    )

    expect { Rake::Task[task_name].invoke }.to output(/GrdaWarehouse::Cohort#column_state: checked \d+ row\(s\) - OK/).to_stdout
  end
end
