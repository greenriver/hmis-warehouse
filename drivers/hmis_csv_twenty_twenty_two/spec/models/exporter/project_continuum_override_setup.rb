###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 project continuum override setup', shared_context: :metadata do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:user) { create :user }
  let!(:projects) { create_list :hud_project, 6, data_source_id: data_source.id, ProjectType: 1, ContinuumProject: 0, hud_continuum_funded: nil }
  let!(:enrollments) { create_list :hud_enrollment, 5, data_source_id: data_source.id, EntryDate: 2.weeks.ago }

  def csv_file_path(klass)
    File.join(exporter.file_path, klass.hud_csv_file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 project continuum override setup', include_shared: true
end
