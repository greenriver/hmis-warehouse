
class GrdaWarehouse::ClientBasicMatcher
  def destination_clients_by_id
    @destination_clients_by_id ||= all_destination_clients.group_by { |_, _, _, _, dest_id| dest_id }.
      transform_values { |values| values.map { |client| { SSN: client[2], DOB: client[3], id: client[4] } }.first }
  end

  def check_social(ssn:)
    return [] unless valid_social?(ssn)

    destination_clients_grouped_by_ssn[ssn]&.uniq || []
  end

  def check_birthday(dob:)
    return [] unless dob.present?

    destination_clients_grouped_by_dob[dob]&.uniq || []
  end

  def check_name(first_name:, last_name:)
    clean_first_name = first_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
    clean_last_name = last_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
    return [] unless clean_first_name.present? && clean_last_name.present?

    destination_clients_grouped_by_name[[clean_first_name, clean_last_name]]&.uniq || []
  end

  protected

  def valid_social?(ssn)
    ::HudUtility2024.valid_social?(ssn)
  end

  def all_destination_clients
    @all_destination_clients ||= GrdaWarehouse::Hud::Client.destination.
      pluck(:FirstName, :LastName, :SSN, :DOB, :id).
      map do |first_name, last_name, ssn, dob, id|
      clean_first_name = first_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
      clean_last_name = last_name&.downcase&.strip&.gsub(/[^a-z0-9]/i, '') || ''
      [clean_first_name, clean_last_name, ssn, dob, id]
    end
  end

  private def destination_clients_grouped_by_name
    @destination_clients_grouped_by_name ||= all_destination_clients.group_by { |first_name, last_name, _, _, _| [first_name, last_name] }.
      transform_values { |values| values.map(&:last) }
  end

  private def destination_clients_grouped_by_ssn
    @destination_clients_grouped_by_ssn ||= all_destination_clients.group_by { |_, _, ssn, _, _| ssn }.
      transform_values { |values| values.map(&:last) }
  end

  private def destination_clients_grouped_by_dob
    @destination_clients_grouped_by_dob ||= all_destination_clients.group_by { |_, _, _, dob, _| dob }.
      transform_values { |values| values.map(&:last) }
  end
end
