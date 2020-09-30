RSpec.shared_context '2020 coc code override tests', shared_context: :metadata do
  describe 'When exporting enrollment related item' do
    before(:each) do
      enrollment_exporter.create_export_directory
      enrollment_exporter.set_time_format
      enrollment_exporter.setup_export
    end
    after(:each) do
      enrollment_exporter.remove_export_files
      enrollment_exporter.reset_time_format

      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end
    {
      enrollment_cocs: {
        export_method: :export_enrollment_cocs,
        export_class: GrdaWarehouse::Export::HmisTwentyTwenty::EnrollmentCoc,
      },
      inventories: {
        export_method: :export_inventories,
        export_class: GrdaWarehouse::Export::HmisTwentyTwenty::Inventory,
      },
      project_cocs: {
        export_method: :export_project_cocs,
        export_class: GrdaWarehouse::Export::HmisTwentyTwenty::ProjectCoc,
      },
    }.each do |k, options|
      describe "when exporting #{k}" do
        before(:each) do
          enrollment_exporter.public_send(options[:export_method])
          @exported_class = options[:export_class]
        end
        it 'enrollment scope should find one enrollment' do
          expect(enrollment_exporter.enrollment_scope.count).to eq 1
        end
        it 'creates one CSV file' do
          expect(File.exist?(csv_file_path(enrollment_exporter, @exported_class))).to be true
        end
        it "adds one row to the #{options[:export_class].name} CSV file" do
          csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
          expect(csv.count).to eq 1
        end
        it "CoCCode from CSV matches CoCCode from #{options[:export_class].name}" do
          csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
          expect(csv.first['CoCCode']).to eq @exported_class.first.CoCCode.to_s
        end
      end
    end

    describe 'when CoC Code is missing' do
      {
        enrollment_cocs: {
          export_method: :export_enrollment_cocs,
          export_class: GrdaWarehouse::Export::HmisTwentyTwenty::EnrollmentCoc,
        },
        inventories: {
          export_method: :export_inventories,
          export_class: GrdaWarehouse::Export::HmisTwentyTwenty::Inventory,
        },
      }.each do |k, options|
        describe "when exporting #{k}" do
          before(:each) do
            @exported_class = options[:export_class]
            @exported_class.update_all(CoCCode: nil)
            enrollment_exporter.public_send(options[:export_method])
          end

          after(:each) do
            # The enrollments and project sequences seem to drift.
            # This ensures we'll have one to test
            FactoryBot.reload
          end

          it "adds one row to the #{options[:export_class].name} CSV file" do
            csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
            expect(csv.count).to eq 1
          end
          it 'CoCCode from CSV matches CoCCode from ProjectCoC' do
            csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
            expect(csv.first['CoCCode']).to eq project_cocs.first.CoCCode.to_s
          end
        end
        describe "when exporting #{k} and Project has more than one CoCCode" do
          before(:each) do
            @exported_class = options[:export_class]
            @exported_class.update_all(CoCCode: nil)
            # Force project to have multiple distinct CoC Codes
            GrdaWarehouse::Hud::ProjectCoc.
              joins(:project).
              merge(GrdaWarehouse::Hud::Project.where.not(id: projects.first.id)).
              update_all(
                ProjectID: projects.first.ProjectID,
                CoCCode: 'XX-505',
                data_source_id: projects.first.data_source_id,
              )
            enrollment_exporter.public_send(options[:export_method])
          end

          after(:each) do
            # The enrollments and project sequences seem to drift.
            # This ensures we'll have one to test
            FactoryBot.reload
          end

          it "adds one row to the #{options[:export_class].name} CSV file" do
            csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
            expect(csv.count).to eq 1
          end
          it 'CoCCode from CSV is blank' do
            csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
            expect(csv.first['CoCCode']).to be_blank
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2020 coc code override tests', include_shared: true
end
