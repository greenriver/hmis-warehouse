require 'rails_helper'
include ArelHelper

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFour, type: :model do
  # NOTE: The date range of the report is limited and will not include everyone in the import file
  describe 'project data quality V4' do
    before(:all) do
      import_fixture
    end
    after(:all) do
      cleanup_fixture
    end

    describe 'a single project report' do
      before(:all) do
        @report = create :data_quality_report_version_four, :single_project
        @project = @report.project
        @range = ::Filters::DateRange.new(start: @report.start, end: @report.end)
        @report.run!
      end
      after(:all) do
      end
      it 'loads clients with enrollments open during the report range' do
        open_enrollments = GrdaWarehouse::Hud::Enrollment
                           .open_during_range(@range)
                           .where(ProjectID: @report.project.ProjectID)
                           .distinct.select(:PersonalID).count

        client_count = @report.source_enrollments.distinct.select(:PersonalID).count

        aggregate_failures 'checking counts' do
          expect(client_count).to eq 92
          expect(client_count).to eq open_enrollments
        end
      end

      it 'creates equivalent report_enrollments' do
        open_enrollments = GrdaWarehouse::Hud::Enrollment
                           .open_during_range(@range)
                           .where(ProjectID: @report.project.ProjectID)
                           .distinct.select(:EnrollmentID).count

        report_enrollments = @report.enrollments.count
        expect(open_enrollments).to eq report_enrollments
      end

      it 'name refused' do
        key = :name
        enrollment_count = @report.enrollments.where(name_refused: true).count
        report_counts = @report.project_completeness(hud_project: @project)
        index = report_counts[:columns].index(key)
        report_count = report_counts[:data]["Don't Know / Refused"][index]

        aggregate_failures 'checking counts' do
          expect(enrollment_count).to eq 2
          expect(enrollment_count).to eq report_count
        end
      end

      it 'name not collected' do
        key = :name
        enrollment_count = @report.enrollments.where(name_not_collected: true).count
        report_counts = @report.project_completeness(hud_project: @project)
        index = report_counts[:columns].index(key)
        report_count = report_counts[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(enrollment_count).to eq 2
          expect(enrollment_count).to eq report_count
        end
      end

      it 'ssn refused' do
        # FIXME: use source data for left side.
        key = :ssn
        enrollment_count = @report.enrollments.where(ssn_refused: true).count
        report_counts = @report.project_completeness(hud_project: @project)
        index = report_counts[:columns].index(key)
        report_count = report_counts[:data]["Don't Know / Refused"][index]

        aggregate_failures 'checking counts' do
          expect(enrollment_count).to eq 3
          expect(enrollment_count).to eq report_count
        end
      end

      it 'ssn not collected' do
        # FIXME
        key = :ssn
        clients = GrdaWarehouse::Hud::Client.where(SSNDataQuality: 99)
                                            .joins(:enrollments)
                                            .merge(
                                              GrdaWarehouse::Hud::Enrollment.open_during_range(@range)
                                                .where(ProjectID: @report.project.ProjectID),
                                            ).distinct.pluck(:id, :SSNDataQuality)

        report_counts = @report.project_completeness(hud_project: @project)
        index = report_counts[:columns].index(key)
        report_count = report_counts[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(clients.count).to eq 63
          expect(clients.count).to eq report_count
        end
      end
    end

    #   describe 'when looking at universal elements' do
    #     before do
    #       report.start_report
    #       report.calculate_missing_universal_elements
    #     end

    #     it 'has the appropriate number of total clients' do
    #       count = report.report['total_clients']
    #       open_enrollments = GrdaWarehouse::Hud::Enrollment
    #                          .open_during_range(range)
    #                          .where(ProjectID: report.project.ProjectID)
    #                          .distinct.count(:PersonalID)

    #       aggregate_failures 'counting clients' do
    #         expect(count).to eq 92
    #         expect(count).to eq open_enrollments
    #       end
    #     end

    #     it 'has the appropriate number of missing names' do
    #       count = report.report['missing_name']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       # A field is missing if the DQ is 99 or empty, even if the field itself contains data
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         NameDataQuality: [99, nil, ''],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, FirstName: [nil, ''],
    #       )
    #                                            .where.not(NameDataQuality: 9)
    #                                            .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, LastName: [nil, ''],
    #       )
    #                                            .where.not(NameDataQuality: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 35
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused names' do
    #       count = report.report['refused_name']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         NameDataQuality: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of missing dob' do
    #       # Excludes refused
    #       count = report.report['missing_dob']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         DOBDataQuality: [99, nil, ''],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, DOB: [nil, ''],
    #       )
    #                                            .where.not(DOBDataQuality: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 33
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused dob' do
    #       count = report.report['refused_dob']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         DOBDataQuality: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of missing ssn' do
    #       # Excludes refused
    #       count = report.report['missing_ssn']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         SSNDataQuality: [99, nil, ''],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, SSN: [nil, ''],
    #       )
    #                                            .where.not(SSNDataQuality: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 67
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused ssn' do
    #       count = report.report['refused_ssn']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         SSNDataQuality: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing race' do
    #       count = report.report['missing_race']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         RaceNone: [99],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, AmIndAKNative: [0, 99, nil, ''],
    #         Asian: [0, 99, nil, ''],
    #         BlackAfAmerican: [0, 99, nil, ''],
    #         NativeHIOtherPacific: [0, 99, nil, ''],
    #         White: [0, 99, nil, '']
    #       )
    #                                            .where.not(RaceNone: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 65
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused race' do
    #       count = report.report['refused_race']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         RaceNone: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing ethnicity' do
    #       count = report.report['missing_ethnicity']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Ethnicity: [99, nil, ''],
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 60
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused ethnicity' do
    #       count = report.report['refused_race']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Ethnicity: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing gender' do
    #       count = report.report['missing_gender']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Gender: [99, nil, ''],
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 5
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused gender' do
    #       count = report.report['refused_gender']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Gender: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing veteran status' do
    #       count = report.report['missing_veteran']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       eighteen = report.start - 18.years
    #       c_t = GrdaWarehouse::Hud::Client.arel_table
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         VeteranStatus: [99, nil, ''],
    #       )
    #                                           .where(c_t[:DOB].lteq(eighteen).or(c_t[:DOB].eq('')).or(c_t[:DOB].eq(nil)))
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 46
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused veteran status' do
    #       count = report.report['refused_veteran']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       eighteen = report.start - 18.years
    #       c_t = GrdaWarehouse::Hud::Client.arel_table
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         VeteranStatus: 9,
    #       )
    #                                           .where(c_t[:DOB].lteq(eighteen).or(c_t[:DOB].eq('')).or(c_t[:DOB].eq(nil)))
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end
    #   end

    #   describe 'when looking at missing enrollment elements' do
    #     before do
    #       report.start_report
    #       report.add_missing_enrollment_elements
    #     end

    #     it 'has the appropriate number of clients with missing disabling condition' do
    #       count = report.report['missing_disabling_condition']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { DisablingCondition: [99, nil, ''] },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 88
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused disabling condition' do
    #       count = report.report['refused_disabling_condition']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { DisablingCondition: 9 },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing living situation' do
    #       count = report.report['missing_prior_living_situation']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { LivingSituation: [99, nil, ''] },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 87
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused living situation' do
    #       count = report.report['refused_prior_living_situation']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { LivingSituation: 9 },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing income at entry' do
    #       count = report.report['missing_income_at_entry']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq

    #       expected_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                                    .entry_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                    .where(client_id: client_ids)
    #                                                                    .distinct
    #                                                                    .pluck(:client_id)

    #       valid_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                                 .entry_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                 .includes(enrollment: :income_benefits_at_entry)
    #                                                                 .where(
    #                                                                   ib_t[:IncomeFromAnySource].in([1, 0])
    #                                                                   .and(ib_t[:TotalMonthlyIncome].not_eq(nil))
    #                                                                   .or(ib_t[:IncomeFromAnySource].in([8, 9])),
    #                                                                 )
    #                                                                 .where(client_id: client_ids)
    #                                                                 .distinct
    #                                                                 .pluck(:client_id)

    #       missing = expected_client_ids - valid_client_ids

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 39
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused income at entry' do
    #       count = report.report['refused_income_at_entry']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .entry_within_date_range(start_date: report.start, end_date: report.end)
    #                                                        .joins(enrollment: :income_benefits_at_entry_all_sources_refused)
    #                                                        .where(client_id: client_ids)
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing income at exit' do
    #       count = report.report['missing_income_at_exit']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       expected_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.exit
    #                                                                    .exit_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                    .where(client_id: client_ids)
    #                                                                    .distinct
    #                                                                    .pluck(:client_id)

    #       valid_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.exit
    #                                                                 .exit_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                 .includes(enrollment: %i[income_benefits_at_exit exit])
    #                                                                 .where(
    #                                                                   ib_t[:IncomeFromAnySource].in([1, 0])
    #                                                                   .and(ib_t[:TotalMonthlyIncome].not_eq(nil))
    #                                                                   .or(ib_t[:IncomeFromAnySource].in([8, 9])),
    #                                                                 )
    #                                                                 .where(client_id: client_ids)
    #                                                                 .distinct
    #                                                                 .pluck(:client_id)

    #       missing = expected_client_ids - valid_client_ids

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused income at exit' do
    #       count = report.report['refused_income_at_exit']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::ServiceHistoryEnrollment.exit
    #                                                        .exit_within_date_range(start_date: report.start, end_date: report.end)
    #                                                        .joins(enrollment: %i[income_benefits_at_exit_all_sources_refused exit])
    #                                                        .where(client_id: client_ids)
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing destinations at exit' do
    #       count = report.report['missing_destination']

    #       client_ids = []
    #       report.leavers.each do |leaver|
    #         report.enrollments[leaver].each do |enrollment|
    #           client_ids << enrollment[:destination_id]
    #         end
    #       end
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment
    #                 .where(
    #                   client_id: client_ids.uniq,
    #                   destination: [99, nil, ''],
    #                 )
    #                 .pluck(:client_id)

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused destination at exit' do
    #       count = report.report['refused_destination']

    #       client_ids = []
    #       report.leavers.each do |leaver|
    #         report.enrollments[leaver].each do |enrollment|
    #           client_ids << enrollment[:destination_id]
    #         end
    #       end
    #       refused = GrdaWarehouse::ServiceHistoryEnrollment
    #                 .where(
    #                   client_id: client_ids,
    #                   destination: 9,
    #                 )
    #                 .pluck(:client_id)

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end
    #   end
    # end

    # describe 'a project group report' do
    #   let(:report) { create :data_quality_report_version_three, :project_group }
    #   let(:range) { ::Filters::DateRange.new(start: report.start, end: report.end) }

    #   it 'loads all projects' do
    #     expect(report.projects.count).to eq 3
    #   end

    #   it 'loads all clients' do
    #     expect(report.clients.map { |m| m[:destination_id] }.uniq.count).to eq 112
    #   end

    #   describe 'when looking at universal elements' do
    #     before do
    #       report.start_report
    #       report.calculate_missing_universal_elements
    #     end

    #     it 'has the appropriate number of total clients' do
    #       count = report.report['total_clients']
    #       open_enrollments = GrdaWarehouse::Hud::Enrollment
    #                          .open_during_range(range)
    #                          .where(ProjectID: report.projects.pluck(:ProjectID))
    #                          .distinct.count(:PersonalID)

    #       aggregate_failures 'counting clients' do
    #         expect(count).to eq 112
    #         expect(count).to eq open_enrollments
    #       end
    #     end

    #     it 'has the appropriate number of missing names' do
    #       count = report.report['missing_name']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       # A field is missing if the DQ is 99 or empty, even if the field itself contains data
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         NameDataQuality: [99, nil, ''],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, FirstName: [nil, ''],
    #       )
    #                                            .where.not(NameDataQuality: 9)
    #                                            .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, LastName: [nil, ''],
    #       )
    #                                            .where.not(NameDataQuality: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 35
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused names' do
    #       count = report.report['refused_name']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         NameDataQuality: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of missing dob' do
    #       # Excludes refused
    #       count = report.report['missing_dob']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         DOBDataQuality: [99, nil, ''],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, DOB: [nil, ''],
    #       )
    #                                            .where.not(DOBDataQuality: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 33
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused dob' do
    #       count = report.report['refused_dob']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         DOBDataQuality: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of missing ssn' do
    #       # Excludes refused
    #       count = report.report['missing_ssn']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         SSNDataQuality: [99, nil, ''],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, SSN: [nil, ''],
    #       )
    #                                            .where.not(SSNDataQuality: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 67
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused ssn' do
    #       count = report.report['refused_ssn']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         SSNDataQuality: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 3
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing race' do
    #       count = report.report['missing_race']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         RaceNone: [99],
    #       )
    #                                           .pluck(:id)
    #       missing += GrdaWarehouse::Hud::Client.where(
    #         id: client_ids, AmIndAKNative: [0, 99, nil, ''],
    #         Asian: [0, 99, nil, ''],
    #         BlackAfAmerican: [0, 99, nil, ''],
    #         NativeHIOtherPacific: [0, 99, nil, ''],
    #         White: [0, 99, nil, '']
    #       )
    #                                            .where.not(RaceNone: 9)
    #                                            .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 65
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused race' do
    #       count = report.report['refused_race']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         RaceNone: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing ethnicity' do
    #       count = report.report['missing_ethnicity']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Ethnicity: [99, nil, ''],
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 60
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused ethnicity' do
    #       count = report.report['refused_race']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Ethnicity: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing gender' do
    #       count = report.report['missing_gender']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Gender: [99, nil, ''],
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 5
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused gender' do
    #       count = report.report['refused_gender']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         Gender: 9,
    #       )
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing veteran status' do
    #       count = report.report['missing_veteran']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       eighteen = report.start - 18.years
    #       c_t = GrdaWarehouse::Hud::Client.arel_table
    #       missing = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         VeteranStatus: [99, nil, ''],
    #       )
    #                                           .where(c_t[:DOB].lteq(eighteen).or(c_t[:DOB].eq('')).or(c_t[:DOB].eq(nil)))
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 46
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of refused veteran status' do
    #       count = report.report['refused_veteran']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       eighteen = report.start - 18.years
    #       c_t = GrdaWarehouse::Hud::Client.arel_table
    #       refused = GrdaWarehouse::Hud::Client.where(
    #         id: client_ids,
    #         VeteranStatus: 9,
    #       )
    #                                           .where(c_t[:DOB].lteq(eighteen).or(c_t[:DOB].eq('')).or(c_t[:DOB].eq(nil)))
    #                                           .pluck(:id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end
    #   end

    #   describe 'when looking at missing enrollment elements' do
    #     before do
    #       report.start_report
    #       report.add_missing_enrollment_elements
    #     end

    #     it 'has the appropriate number of clients with missing disabling condition' do
    #       count = report.report['missing_disabling_condition']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { DisablingCondition: [99, nil, ''] },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 89
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused disabling condition' do
    #       count = report.report['refused_disabling_condition']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { DisablingCondition: 9 },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing living situation' do
    #       count = report.report['missing_prior_living_situation']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { LivingSituation: [99, nil, ''] },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 88
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused living situation' do
    #       count = report.report['refused_prior_living_situation']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .joins(enrollment: :client)
    #                                                        .where(
    #                                                          client_id: client_ids,
    #                                                          Enrollment: { LivingSituation: 9 },
    #                                                        )
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing income at entry' do
    #       count = report.report['missing_income_at_entry']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq

    #       expected_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                                    .entry_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                    .where(client_id: client_ids)
    #                                                                    .distinct
    #                                                                    .pluck(:client_id)

    #       valid_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                                 .entry_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                 .includes(enrollment: :income_benefits_at_entry)
    #                                                                 .where(
    #                                                                   ib_t[:IncomeFromAnySource].in([1, 0])
    #                                                                   .and(ib_t[:TotalMonthlyIncome].not_eq(nil))
    #                                                                   .or(ib_t[:IncomeFromAnySource].in([8, 9])),
    #                                                                 )
    #                                                                 .where(client_id: client_ids)
    #                                                                 .distinct
    #                                                                 .pluck(:client_id)

    #       missing = expected_client_ids - valid_client_ids

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 42
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused income at entry' do
    #       count = report.report['refused_income_at_entry']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::ServiceHistoryEnrollment.entry
    #                                                        .entry_within_date_range(start_date: report.start, end_date: report.end)
    #                                                        .joins(enrollment: :income_benefits_at_entry_all_sources_refused)
    #                                                        .where(client_id: client_ids)
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'checking counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing income at exit' do
    #       count = report.report['missing_income_at_exit']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq

    #       expected_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.exit
    #                                                                    .exit_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                    .where(client_id: client_ids)
    #                                                                    .distinct
    #                                                                    .pluck(:client_id)

    #       valid_client_ids = GrdaWarehouse::ServiceHistoryEnrollment.exit
    #                                                                 .exit_within_date_range(start_date: report.start, end_date: report.end)
    #                                                                 .includes(enrollment: %i[income_benefits_at_exit exit])
    #                                                                 .where(
    #                                                                   ib_t[:IncomeFromAnySource].in([1, 0])
    #                                                                   .and(ib_t[:TotalMonthlyIncome].not_eq(nil))
    #                                                                   .or(ib_t[:IncomeFromAnySource].in([8, 9])),
    #                                                                 )
    #                                                                 .where(client_id: client_ids)
    #                                                                 .distinct
    #                                                                 .pluck(:client_id)

    #       missing = expected_client_ids - valid_client_ids

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 2
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused income at exit' do
    #       count = report.report['refused_income_at_exit']

    #       client_ids = report.clients.map { |client| client[:destination_id] }.uniq
    #       refused = GrdaWarehouse::ServiceHistoryEnrollment.exit
    #                                                        .exit_within_date_range(start_date: report.start, end_date: report.end)
    #                                                        .joins(enrollment: %i[income_benefits_at_exit_all_sources_refused exit])
    #                                                        .where(client_id: client_ids)
    #                                                        .pluck(:client_id)

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with missing destinations at exit' do
    #       count = report.report['missing_destination']

    #       client_ids = []
    #       report.leavers.each do |leaver|
    #         report.enrollments[leaver].each do |enrollment|
    #           client_ids << enrollment[:destination_id]
    #         end
    #       end
    #       missing = GrdaWarehouse::ServiceHistoryEnrollment
    #                 .where(
    #                   client_id: client_ids.uniq,
    #                   destination: [99, nil, ''],
    #                 )
    #                 .pluck(:client_id)

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq missing.uniq.count
    #       end
    #     end

    #     it 'has the appropriate number of clients with refused destination at exit' do
    #       count = report.report['refused_destination']

    #       client_ids = []
    #       report.leavers.each do |leaver|
    #         report.enrollments[leaver].each do |enrollment|
    #           client_ids << enrollment[:destination_id]
    #         end
    #       end
    #       refused = GrdaWarehouse::ServiceHistoryEnrollment
    #                 .where(
    #                   client_id: client_ids,
    #                   destination: 9,
    #                 )
    #                 .pluck(:client_id)

    #       aggregate_failures 'compare counts' do
    #         expect(count).to eq 1
    #         expect(count).to eq refused.uniq.count
    #       end
    #     end
    #   end
    # end
  end

  def import_fixture
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :s3)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    @file_path = 'spec/fixtures/files/importers/hmis_six_on_one/project_data_quality'
    @source_file_path = File.join(@file_path, 'source')
    @import_path = File.join(@file_path, @data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(@source_file_path, @import_path)

    importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
    importer.import!
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Update.new(force_sequential_processing: true).run!
    Delayed::Worker.new.work_off(2)
  end

  def cleanup_fixture
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    FileUtils.rm_rf(@import_path) unless @import_path == @file_path
  end
end
