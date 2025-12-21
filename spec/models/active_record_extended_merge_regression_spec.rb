# frozen_string_literal: true

require 'rails_helper'
require_relative '../../drivers/homeless_summary_report/spec/models/report_context'

# Active record has a situation where if it is passed a nested merge (unclear how deeply nested it needs to be)
# it calls `.equality?` on the sides of the merge, and if one is a SqlLiteral, it raises an error.
# This canary intentionally disables the initializer (config/initializers/arel_notes_sql_literal.rb) via env var
# to surface the regression.
# Run with: SKIP_AREL_SQL_LITERAL_INITIALIZER=1 dcr spec rspec spec/models/active_record_extended_merge_regression_spec.rb
# If this test starts failing, it might mean that the regression has been fixed and the initializer can be removed.

RSpec.describe 'ActiveRecord merge with SqlLiteral canary' do
  include_context 'report context'

  before(:all) do
    setup(default_setup_path) if ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'
  end

  after(:all) do
    cleanup if ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'
  end

  it 'reproduces merge failure from HSR smoketest (coc_filter path)' do
    skip 'Set SKIP_AREL_SQL_LITERAL_INITIALIZER=1 to run this canary' unless ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'
    expect { run!(coc_filter) }.to raise_error(NoMethodError, /equality\?/)
  end
end
