RSpec.shared_context '2022 project coc zip override setup', shared_context: :metadata do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:user) { create :user }
  let!(:projects) { create_list :hud_project, 5, data_source_id: data_source.id, ProjectType: 1, act_as_project_type: 13, computed_project_type: 13 }
  let!(:project_cocs) { create_list :hud_project_coc, 5, CoCCode: 'XX-500', data_source_id: data_source.id, Zip: '11111' }
  let!(:enrollments) { create_list :hud_enrollment, 5, data_source_id: data_source.id, EntryDate: 2.weeks.ago }
  # Note the exporter joins client, so we need to include those even though they aren't
  # explicityly checked
  let!(:clients) { create_list :hud_client, 5, data_source_id: data_source.id }

  def csv_file_path(exporter, klass)
    File.join(exporter.file_path, klass.hud_csv_file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 project coc zip override setup', include_shared: true
end
