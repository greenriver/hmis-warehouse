###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'form_transfer rake tasks', type: :task do
  let!(:data_source) { create(:hmis_data_source) }
  let!(:pets) { create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT') }
  let!(:other) { create(:hmis_form_definition, data_source: data_source, identifier: 'other', role: 'CUSTOM_ASSESSMENT') }
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, 'export.json') }

  before do
    Rake::Task.clear
    Rake.application = Rake::Application.new
    load Rails.root.join('drivers/hmis/lib/tasks/form_transfer.rake')
    Rake::Task.define_task(:environment)
  end

  after { FileUtils.remove_entry(dir) }

  def run_task(name, *args, env: {})
    allow(ENV).to receive(:[]).and_call_original
    task_env = ['IDENTIFIERS', 'ROLES', 'PROJECT_IDS', 'INCLUDE_PROJECTS', 'INCLUDE_CE', 'DRY_RUN', 'CONFIRM_IMPORT_INTO'].index_with(nil)
    task_env.merge('DATA_SOURCE_ID' => data_source.id.to_s).merge(env).each do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end
    expect { Rake::Task[name].invoke(*args) }.to output.to_stdout
  end

  it 'exports the identifiers named in IDENTIFIERS to the given file' do
    run_task('form_transfer:export', path, env: { 'IDENTIFIERS' => 'pets' })

    expect(JSON.parse(File.read(path))['definitions'].map { |d| d['identifier'] }).to eq(['pets'])
  end

  it 'imports a file, and DRY_RUN=true leaves the database unchanged' do
    run_task('form_transfer:export', path, env: { 'IDENTIFIERS' => 'pets', 'INCLUDE_PROJECTS' => 'false' })
    Hmis::Form::Definition.where(id: pets.id).delete_all

    run_task('form_transfer:import', path, env: { 'DRY_RUN' => 'true' })
    expect(Hmis::Form::Definition.where(data_source_id: data_source.id, identifier: 'pets').count).to eq(0)

    Rake::Task['form_transfer:import'].reenable
    run_task('form_transfer:import', path)
    expect(Hmis::Form::Definition.where(data_source_id: data_source.id, identifier: 'pets').count).to eq(1)
  end

  it 'passes CONFIRM_IMPORT_INTO to the environment gate' do
    run_task('form_transfer:export', path, env: { 'IDENTIFIERS' => 'pets', 'INCLUDE_PROJECTS' => 'false' })
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('staging'))

    expect { run_task('form_transfer:import', path, env: { 'CONFIRM_IMPORT_INTO' => 'production' }) }.to raise_error(RuntimeError, /Refusing to import/)
  end

  it 'requires a filename' do
    expect { Rake::Task['form_transfer:import'].invoke }.to raise_error(ArgumentError, 'Usage: rails driver:hmis:form_transfer:import[FILENAME]')
  end
end
