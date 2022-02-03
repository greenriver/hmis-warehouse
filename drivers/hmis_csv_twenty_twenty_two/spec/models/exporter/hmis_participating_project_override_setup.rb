###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 HMIS Participating Project override setup', shared_context: :metadata do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:user) { create :user }
  let!(:projects) { create_list :hud_project, 5, data_source_id: data_source.id, ProjectType: 1, HMISParticipatingProject: 1, hmis_participating_project_override: 0 }
  let!(:enrollments) { create_list :hud_enrollment, 5, data_source_id: data_source.id, EntryDate: 2.weeks.ago }
  # Note the exporter joins client, so we need to include those even though they aren't
  # explicitly checked
  let!(:clients) { create_list :hud_client, 5, data_source_id: data_source.id }

  def csv_file_path(exporter, klass)
    File.join(exporter.file_path, klass.hud_csv_file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 HMIS Participating Project override setup', include_shared: true
end
