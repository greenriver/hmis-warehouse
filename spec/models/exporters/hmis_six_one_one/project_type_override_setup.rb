RSpec.shared_context 'project type override setup', shared_context: :metadata do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:user) { create :user }
  let!(:projects) { create_list :hud_project, 5, data_source_id: data_source.id, ProjectType: 1, act_as_project_type: 13, computed_project_type: 13 }
  let!(:enrollments) { create_list :hud_enrollment, 5, data_source_id: data_source.id, EntryDate: 2.weeks.ago }

  def csv_file_path(exporter, klass)
    File.join(exporter.file_path, klass.file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'project type override setup', include_shared: true
end
