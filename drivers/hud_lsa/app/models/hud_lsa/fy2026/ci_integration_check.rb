###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Runs the FY2026 LSA generator end-to-end in `test` mode against a real (typically
# containerized) MS SQL Server, then compares the generated output to the HUD sample
# result fixtures using the existing HudLsa::Generators::Fy2026::LsaComparisonTool.
#
# Fixtures are gitignored and pulled from S3 in CI (see the lsa_integration_test
# workflow), mirroring the datalab testkit. Intended to be driven by the
# driver:hud_lsa:ci_integration_test rake task, NOT the normal RSpec suite (which
# disables SQL Server via NO_LSA_RDS). All SQL Server references live inside methods
# so the class still loads under the stub.
module HudLsa::Fy2026
  class CiIntegrationCheck
    # Expected-output fixture dir per scope (HUD sample results; see driver README).
    FIXTURE_DIRS = {
      lsa: 'drivers/hud_lsa/spec/fixtures/files/lsa/fy2026/sample_results',
      hic: 'drivers/hud_lsa/spec/fixtures/files/lsa/fy2026/sample_hic_results',
    }.freeze

    OUTPUT_ROOT = 'tmp/lsa_ci_output'

    def self.run!(scope:)
      new(scope: scope).run!
    end

    def initialize(scope:)
      @scope = scope.to_sym
      raise ArgumentError, "unknown scope: #{scope.inspect} (expected one of #{FIXTURE_DIRS.keys})" unless FIXTURE_DIRS.key?(@scope)
    end

    # Returns true when the run completed and output matched the fixtures. Raises if
    # the run itself fails (connection, queries, no output, missing fixtures) so the
    # task exits non-zero with a useful message.
    def run!
      report = nil
      log "=== LSA CI integration check: #{@scope} ==="
      report = build_report
      log "STAGE report-built: report ##{report.id}"

      report.run!
      report.reload
      raise "LSA run did not reach Completed (state=#{report.state.inspect}): #{report.error_details}" unless report.state == 'Completed'

      log 'STAGE completed: report reached Completed (SQL Server connected, all queries ran)'

      generated_dir = extract_generated_csvs(report)
      log "STAGE output: #{Dir.glob(File.join(generated_dir, '*.csv')).size} CSV file(s) produced"

      compare(generated_dir)
    ensure
      cleanup(report)
    end

    private

    def fixture_dir
      Rails.root.join(FIXTURE_DIRS[@scope]).to_s
    end

    def output_dir
      Rails.root.join(OUTPUT_ROOT, @scope.to_s).to_s
    end

    def expected_filenames
      LsaSqlServer.models_by_filename.keys
    end

    def build_report
      ensure_factories_loaded
      # Unique email so repeated local runs (no transactional rollback) don't
      # collide with users left over from previous runs.
      @created_user = FactoryBot.create(:acl_user, email: "lsa-ci-#{SecureRandom.hex(8)}@example.com")
      record = FactoryBot.create(
        :hud_reports_report_instance,
        type: 'HudLsa::Generators::Fy2026::Lsa',
        options: report_options,
        question_names: [],
      )
      record.update!(user_id: @created_user.id)

      report = HudLsa::Generators::Fy2026::Lsa.find(record.id)
      report.test = true
      report.destroy_rds = false
      report.test_type = @scope
      report
    end

    def report_options
      today = Date.current
      {
        start: (today - 1.year).beginning_of_month.to_s,
        end: today.to_s,
        coc_code: 'XX-501',
        lsa_scope: @scope == :hic ? HudLsa::Fy2026::Report.available_lsa_scopes['HIC'] : 1,
      }
    end

    def ensure_factories_loaded
      FactoryBot.find_definitions unless FactoryBot.factories.registered?(:hud_reports_report_instance)
    end

    # Download the result_file zip and unzip it into output_dir (kept for the CI
    # artifact); returns that directory.
    def extract_generated_csvs(report)
      raise 'result_file was not attached to the report' unless report.result_file.attached?

      FileUtils.rm_rf(output_dir)
      FileUtils.mkdir_p(output_dir)
      zip_path = File.join(output_dir, 'result_file.zip')
      File.binwrite(zip_path, report.result_file.download)

      Zip::File.open(zip_path) do |zip|
        zip.each { |entry| File.binwrite(File.join(output_dir, entry.name), entry.get_input_stream.read) }
      end
      File.delete(zip_path)
      output_dir
    end

    # Compares generated output to the fixtures with the shared LsaComparisonTool
    # (which drops per-run volatile columns). Fails loudly if fixtures are missing
    # so an empty/unfetched fixture dir can't produce a vacuous pass.
    def compare(generated_dir)
      verify_files_present!(generated_dir)

      diffs = HudLsa::Generators::Fy2026::LsaComparisonTool.new(fixture_dir, generated_dir).compare
      all_ok = true
      diffs.each do |sample_path, diff|
        name = File.basename(sample_path)
        missing = diff['sample - generated']
        extra = diff['generated - sample']
        if missing.empty? && extra.empty?
          log "  [OK  ] #{name}"
        else
          all_ok = false
          log "  [FAIL] #{name}: #{missing.size} expected row(s) missing, #{extra.size} unexpected row(s)"
          missing.first(2).each { |row| log "      expected:  #{row.inspect}" }
          extra.first(2).each { |row| log "      generated: #{row.inspect}" }
        end
      end
      log(all_ok ? "STAGE compare: PASS (all #{diffs.size} files match)" : 'STAGE compare: FAIL')
      all_ok
    end

    def verify_files_present!(generated_dir)
      missing_fixtures = expected_filenames.reject { |f| File.exist?(File.join(fixture_dir, f)) }
      raise "fixture files missing from #{fixture_dir} (did the S3 fetch run?): #{missing_fixtures.join(', ')}" if missing_fixtures.any?

      missing_generated = expected_filenames.reject { |f| File.exist?(File.join(generated_dir, f)) }
      raise "generated output missing files: #{missing_generated.join(', ')}" if missing_generated.any?
    end

    def cleanup(report)
      if report
        report.summary_result&.destroy
        report.result_file.purge if report.result_file.attached?
        report.intermediate_file.purge if report.intermediate_file.attached?
        report.destroy
      end
      # delete (not destroy) to skip dependent-association callbacks that touch
      # columns absent from the test schema; the CI database is ephemeral.
      @created_user&.delete
    rescue StandardError => e
      log "cleanup warning: #{e.message}"
    end

    def log(message)
      puts message
      Rails.logger.info(message)
    end
  end
end
