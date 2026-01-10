# frozen_string_literal: true

require 'json'
require 'open3'
require 'tempfile'

RSpec.describe 'bin/ci_matrix_router.rb' do
  let(:script_path) { File.expand_path('../../bin/ci_matrix_router.rb', __dir__) }
  let(:github_output) { Tempfile.new('github_output') }
  let(:env) do
    {
      'GITHUB_OUTPUT' => github_output.path,
      'COMMIT_MSG' => '',
      'EVENT_NAME' => 'push',
      'INPUT_TEST_PATH' => '',
      'INPUT_WITH_OKTA' => 'false',
      'INPUT_WITH_LOGGING' => 'false',
    }
  end

  after do
    github_output.unlink
  end

  def run_script(custom_env = {})
    full_env = env.merge(custom_env)
    stdout, stderr, status = Open3.capture3(full_env, "ruby #{script_path}")
    unless status.success?
      puts "STDOUT: #{stdout}"
      puts "STDERR: #{stderr}"
    end
    expect(status.success?).to be true
    parse_output
  end

  def parse_output
    File.read(github_output.path).split("\n").each_with_object({}) do |line, hash|
      key, value = line.split('=', 2)
      hash[key] = value
    end
  end

  context 'when it is a pull request' do
    it 'runs all categories by default' do
      output = run_script('EVENT_NAME' => 'pull_request')
      expect(output['run_hmis']).to eq 'true'
      expect(output['run_warehouse']).to eq 'true'
      expect(output['run_unit']).to eq 'true'
      expect(JSON.parse(output['unit_matrix'])['test_group']).not_to be_empty
    end
  end

  context 'when ci-focus is provided in commit message' do
    it 'routes to HMIS if path matches' do
      output = run_script('COMMIT_MSG' => 'debug [ci-focus: drivers/hmis/spec/system/hmis/my_spec.rb]')
      expect(output['run_hmis']).to eq 'true'
      expect(output['run_warehouse']).to eq 'false'
      expect(output['run_unit']).to eq 'false'
      expect(output['focused_path']).to eq 'drivers/hmis/spec/system/hmis/my_spec.rb'

      unit_matrix = JSON.parse(output['unit_matrix'])
      expect(unit_matrix['test_group']).to be_empty
    end

    it 'routes to Warehouse if path matches' do
      output = run_script('COMMIT_MSG' => 'debug [ci-focus: spec/system/rails/my_spec.rb]')
      expect(output['run_hmis']).to eq 'false'
      expect(output['run_warehouse']).to eq 'true'
      expect(output['run_unit']).to eq 'false'
      expect(output['focused_path']).to eq 'spec/system/rails/my_spec.rb'
    end

    it 'routes to unit tests for other paths' do
      output = run_script('COMMIT_MSG' => 'debug [ci-focus: spec/models/user_spec.rb]')
      expect(output['run_hmis']).to eq 'false'
      expect(output['run_warehouse']).to eq 'false'
      expect(output['run_unit']).to eq 'true'
      expect(output['focused_path']).to eq 'spec/models/user_spec.rb'

      unit_matrix = JSON.parse(output['unit_matrix'])
      expect(unit_matrix['test_group']).to eq([{ 'id' => 'focused', 'test_path' => 'spec/models/user_spec.rb' }])
    end
  end

  context 'when flags are provided' do
    it 'enables okta when with-okta is in commit message' do
      output = run_script('COMMIT_MSG' => 'test with-okta')
      expect(output['okta']).to eq 'true'
    end

    it 'enables logging when with-logging is in commit message' do
      output = run_script('COMMIT_MSG' => 'test with-logging')
      expect(output['logging']).to eq 'true'
    end

    it 'enables okta via workflow input' do
      output = run_script('INPUT_WITH_OKTA' => 'true')
      expect(output['okta']).to eq 'true'
    end
  end

  context 'when workflow input test_path is provided' do
    it 'takes precedence over commit message' do
      output = run_script(
        'INPUT_TEST_PATH' => 'spec/models/user_spec.rb',
        'COMMIT_MSG' => 'debug [ci-focus: spec/models/post_spec.rb]',
      )
      expect(output['focused_path']).to eq 'spec/models/user_spec.rb'
    end
  end

  context 'when no focus is provided' do
    it 'loads buckets from file' do
      buckets_file = Tempfile.new('buckets.json')
      buckets_file.write([{ id: 'bucket-1' }].to_json)
      buckets_file.close

      begin
        output = run_script('BUCKETS_FILE' => buckets_file.path)
        unit_matrix = JSON.parse(output['unit_matrix'])
        groups = unit_matrix['test_group']

        expect(groups.find { |g| g['id'] == 'ci_bucket_1' }).not_to be_nil
        expect(groups.find { |g| g['id'] == 'ci_default' }).not_to be_nil
      ensure
        buckets_file.unlink
      end
    end
  end
end
