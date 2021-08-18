###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do
  RSpec.configuration.fixpoints_path = 'drivers/hud_spm_report/spec/fixpoints'
end

SPM_USER_EMAIL = 'spm_reporter@example.com'.freeze

RSpec.shared_context 'HudSpmReport context', shared_context: :metadata do
  before(:context) do
    cleanup
    # puts "  Setting up DB for #{described_class.question_number}"
  end

  after(:context) do
    cleanup
  end

  def cleanup
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
      project_type_codes: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES + [:psh],
    }.freeze
  end

  def default_filter
    ::Filters::HudFilterBase.new(shared_filter)
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
    @data_source = GrdaWarehouse::DataSource.where(name: 'Green River', short_name: 'GR', source_type: :sftp).first_or_create!
    GrdaWarehouse::DataSource.where(name: 'Warehouse', short_name: 'W').first_or_create!
    import(file_path, @data_source)
    @user = User.find_by(email: SPM_USER_EMAIL) || create(:user, email: SPM_USER_EMAIL)
    @user.add_viewable(@data_source)
  end

  def import(file_path, data_source)
    # relative to our own spec fixture files
    file_path = File.join('drivers/hud_spm_report/spec/fixtures/files', file_path)

    import_hmis_csv_fixture(file_path, data_source: data_source)
    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
  end
end
