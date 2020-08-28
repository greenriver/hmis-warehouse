RSpec.shared_context '2020 coc code override setup', shared_context: :metadata do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:clients) { create_list :hud_client, 5, data_source_id: data_source.id }
  let!(:destination_data_source) { create :grda_warehouse_data_source }
  let!(:destination_clients) do
    clients.map do |client|
      attributes = client.attributes
      attributes['data_source_id'] = destination_data_source.id
      attributes['id'] = nil
      dest_client = GrdaWarehouse::Hud::Client.create(attributes)
      GrdaWarehouse::WarehouseClient.create(
        id_in_source: client.PersonalID,
        data_source_id: client.data_source_id,
        source_id: client.id,
        destination_id: dest_client.id,
      )
    end
  end
  let!(:user) { create :user }
  let!(:projects) { create_list :hud_project, 5, data_source_id: data_source.id, ProjectType: 1, act_as_project_type: 13, computed_project_type: 13 }
  let!(:project_cocs) { create_list :hud_project_coc, 5, CoCCode: 'XX-500', data_source_id: data_source.id }
  let!(:inventories) { create_list :hud_inventory, 5, CoCCode: 'XX-501', data_source_id: data_source.id }
  let!(:enrollments) { create_list :hud_enrollment, 5, data_source_id: data_source.id, EntryDate: 2.weeks.ago }
  let!(:enrollment_cocs) { create_list :hud_enrollment_coc, 5, InformationDate: 2.months.ago, CoCCode: 'XX-502', data_source_id: data_source.id }

  def csv_file_path(exporter, klass)
    File.join(exporter.file_path, klass.file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2020 coc code override setup', include_shared: true
end
