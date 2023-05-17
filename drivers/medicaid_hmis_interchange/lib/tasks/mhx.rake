desc "Upload Medicaid homelessness information"
task medicaid_hmis_transfer: [:environment, 'log:info_to_stdout'] do
  MedicaidHmisInterchange::FileExchangeJob.perform_later
end

desc "Query for medicaid ids"
task medicaid_id_query: [:environment, 'log:info_to_stdout'] do
  homeless_clients = GrdaWarehouse::Hud::Client.homeless_on_date
  homeless_clients.where.not(
    id: MedicaidHmisInterchange::Health::ExternalId.pluck(:client_id), # TODO: Re-process invalidated identifiers?
  ).pluck_in_batches(:id, batch_size: 100) do |batch|
    MedicaidHmisInterchange::MedicaidIdLookupJob.set(priority: 13).perform_later(batch)
  end
end
