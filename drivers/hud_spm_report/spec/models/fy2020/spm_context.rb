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

  def cleanup
    puts '  Cleaning up DB'
    @user&.really_destroy!
    User.with_deleted.where(email: SPM_USER_EMAIL).delete_all
  end

  def shared_filter
    {
      start: Date.parse('2020-01-01'),
      end: Date.parse('2020-12-31'),
      coc_codes: ['XX-500'],
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
    klass.new(
      ::HudReports::ReportInstance.from_filter(
        filter,
        klass.title,
        build_for_questions: [question_number],
      ),
    ).run!
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def setup(_file_path)
    # @delete_later = []
    # GrdaWarehouse::Utility.clear!
    # @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    # GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    # import(file_path, @data_source)
    # GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    # GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    # GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!

    # Delayed::Worker.new.work_off(2)
  end

  # def import(file_path, data_source)
  #   source_file_path = File.join(file_path, 'source')
  #   import_path = File.join(file_path, data_source.id.to_s)
  #   # duplicate the fixture file as it gets manipulated
  #   FileUtils.cp_r(source_file_path, import_path)
  #   @delete_later << import_path unless import_path == source_file_path

  #   importer = Importers::HmisTwentyTwenty::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)
  #   importer.import!
  # end
end
