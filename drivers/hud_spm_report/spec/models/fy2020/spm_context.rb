###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do |config| # rubocop:disable Lint/UnusedBlockArgument
  RSpec.configuration.fixpoints_path = 'drivers/hud_spm_report/spec/fixpoints'
end

SPM_USER_EMAIL = 'spm_reporter@example.com'.freeze

RSpec.shared_context 'HudSpmReport context', shared_context: :metadata do
  before(:context) do
    cleanup
    puts '  Setting up DB'
    @user = create(:user, email: SPM_USER_EMAIL)
  end

  after(:context) do
    cleanup
  end

  def assert_report_completed
    assert_equal 'Completed', report_result.state, report_result.failures
    assert_equal [described_class.question_number], report_result.build_for_questions
    assert report_result.remaining_questions.none?
  end

  def cleanup
    puts '  Cleaning up jobs, DB and temporary files'
    Delayed::Job.delete_all
    cleanup_files
    GrdaWarehouse::Utility.clear!
    @user&.really_destroy!
    User.with_deleted.where(email: SPM_USER_EMAIL).delete_all
    HudSpmReport::Fy2020::SpmClient.delete_all
  end

  def shared_filter
    {
      start: Date.parse('2016-1-1'),
      end: Date.parse('2019-10-01'),
      user_id: @user.id,
    }.freeze
  end

  def default_filter
    HudSpmReport::Filters::SpmFilter.new(
      shared_filter.merge(project_ids: []), # FIXME
    )
  end

  def run(filter, question_number)
    # puts "Running #{filter} for #{question_number}"

    klass = HudSpmReport::Generators::Fy2020::Generator
    @generator = klass.new(
      ::HudReports::ReportInstance.from_filter(
        filter,
        klass.title,
        build_for_questions: [question_number],
      ),
    )
    @generator.run!
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def setup(file_path)
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    AccessGroup.maintain_system_groups

    Delayed::Worker.new.work_off(2)
  end

  def import(file_path, data_source)
    @delete_later ||= []
    # relative to our own spec fixture files
    folder_path = Rails.root.join('drivers/hud_spm_report/spec/fixtures/files', file_path)
    source_file_path = File.join(folder_path, 'source')
    import_path = File.join(folder_path, data_source.id.to_s)
    unless import_path == source_file_path
      # duplicate the fixture file as it gets manipulated
      puts "Copying #{source_file_path} => #{import_path} and remembering it needs to be cleaned up"
      FileUtils.cp_r(source_file_path, import_path)
      @delete_later << import_path
    end

    importer = Importers::HmisTwentyTwenty::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)
    importer.import!
  end

  def cleanup_files
    return unless @delete_later

    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
    @delete_later = nil
  end
end
