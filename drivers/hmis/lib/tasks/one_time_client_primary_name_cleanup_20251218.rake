desc 'One time data cleanup to ensure merged clients have primary names'
# rails driver:hmis:cleanup_client_primary_names_20251218
task cleanup_client_primary_names_20251218: [:environment] do
  GrdaWarehouse::DataSource.hmis.each do |data_source|
    # clients with associated name records, but no primary name
    clients = Hmis::Hud::Client.
      joins(:names). # Only clients with at least one custom client name
      left_joins(:primary_name). # Left join to primary names
      where(primary_name: { id: nil }). # Where there is no primary name
      distinct

    puts "Found #{clients.count} clients with missing primary names: #{clients.pluck(:id).join(', ')}"

    clients.find_each do |client|
      # find the first name record that matches this client's name fields (if any)
      primary_name = client.names.find do |name|
        [client.first_name, client.middle_name, client.last_name, client.name_suffix] == [name.first, name.middle, name.last, name.suffix]
      end

      if primary_name.present?
        # if we found one, set it as the primary name
        primary_name.update!(primary: true)
      else
        # if we didn't find one, build a new primary name matching the client's name fields
        client.build_primary_custom_client_name.save!
      end

      updated_count += 1
    end

    puts "Updated #{updated_count} clients with missing primary names"
  end
end
