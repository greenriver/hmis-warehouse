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
    # puts "  Setting up DB for #{described_class.question_number}"
    @user = create(:user, email: SPM_USER_EMAIL)
    @delete_later = [] # We are going to create some temporary folders that need cleanup
  end

  after(:context) do
    cleanup
  end

  def cleanup
    # puts '  Cleaning up DB and temporary files'
    while (path = @delete_later&.pop)
      # puts "Removing #{path}"
      FileUtils.rm_rf(path)
    end

    # these should have been impossible
    HudReports::ReportCell.with_deleted.where(report_instance_id: nil).delete_all

    # scrub any past reports
    reports = HudReports::ReportInstance.with_deleted.where(report_name: HudSpmReport::Generators::Fy2020::Generator.title)
    HudSpmReport::Fy2020::SpmClient.with_deleted.delete_all
    HudReports::UniverseMember.with_deleted.where(universe_membership_type: HudSpmReport::Fy2020::SpmClient.sti_name).delete_all
    HudReports::ReportCell.with_deleted.where(report_instance_id: reports.select(:id)).delete_all
    reports.delete_all

    GrdaWarehouse::Utility.clear!

    User.with_deleted.where(email: SPM_USER_EMAIL).delete_all
  end

  def shared_filter
    {
      start: Date.parse('2016-1-1'),
      end: Date.parse('2019-10-01'),
      user_id: @user.id,
    }.freeze
  end

  def default_filter
    HudSpmReport::Filters::SpmFilter.new(shared_filter)
  end

  def assert_report_completed
    assert_equal 'Completed', report_result.state, report_result.failures
    # assert report_result.remaining_questions.none?
  end

  def run(filter, question_number)
    # puts "Running #{filter} for #{question_number}"
    @report = nil

    klass = HudSpmReport::Generators::Fy2020::Generator
    @generator = klass.new(
      ::HudReports::ReportInstance.from_filter(
        filter,
        klass.title,
        build_for_questions: [question_number],
      ),
    )
    @generator.run!

    @report_result = @generator.report
    @report_result.reload
  end

  attr_reader :report_result

  def setup(file_path)
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')

    import(file_path, @data_source)
  end

  def import(file_path, data_source)
    # relative to our own spec fixture files
    file_path = Rails.root.join('drivers/hud_spm_report/spec/fixtures/files', file_path)
    source_file_path = File.join(file_path, 'source')

    # Importers::HmisTwentyTwenty::Base expects a directory named after that data source
    # to work with and wants file_path to point to its parent. It will potentially
    # tamper with the directory contents so we make a temporary copy of the fixture data
    # and delete it later
    import_path = File.join(file_path, data_source.id.to_s)
    # puts "Creating #{import_path}"
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path

    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
    importer = Importers::HmisTwentyTwenty::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)

    raise 'Somethings is not right' unless importer.import.import_errors.none?

    importer.import!

    # We need this import to be fully processed right now
    # so run various normally async processes
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    AccessGroup.maintain_system_groups
    Delayed::Worker.new.work_off

    importer
  end
end
