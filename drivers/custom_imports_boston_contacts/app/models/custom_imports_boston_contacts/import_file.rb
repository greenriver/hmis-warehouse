###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonContacts
  class ImportFile < GrdaWarehouse::CustomImports::ImportFile
    has_many :rows

    def self.description
      'Boston Custom Contacts'
    end

    def detail_path
      [:custom_imports, :boston_contacts, :file]
    end

    def filename
      file
    end

    def import!
      return unless check_hour

      start_import
      fetch_and_load
      post_process
    end

    # CSV is missing a header for row_number, needs import_file_id, and the others need to be translated
    private def clean_headers(headers)
      headers[0] = 'row_number'
      headers << 'import_file_id'
      headers << 'data_source_id'
      headers.map do |h|
        header_lookup[h] || h
      end
    end

    private def header_lookup
      {
        'Personal ID' => 'personal_id',
        'Contact ID' => 'unique_id',
        'Agency ID' => 'agency_id',
        'Contact Type' => 'contact_type',
        'Name' => 'contact_name',
        'Phone1' => 'phone',
        'Phone2' => 'phone_alternate',
        'Email' => 'email',
        'Note' => 'note',
        'Last Updated Date' => 'contact_updated_at',
        'Added Date' => 'contact_created_at',
        'Private (Yes / No)' => 'private',
      }
    end

    def post_process
      update(status: 'matching')
      matched = 0
      ClientContact.where(source_type: 'CustomImportsBostonContacts::Row').delete_all
      rows.preload(client: :destination_client).find_in_batches do |batch|
        contact_batch = []
        batch.each do |row|
          next unless row.client

          matched += 1
          contact_batch << {
            source_id: row.id,
            source_type: row.class.name,
            client_id: row.client.destination_client.id,
            full_name: row.contact_name,
            contact_type: row.contact_type,
            phone: row.phone,
            phone_alternate: row.phone_alternate,
            email: row.email,
            note: row.note,
          }
        end
        GrdaWarehouse::ClientContact.import(contact_batch)
        summary << "Matched #{matched} services"
        update(status: 'complete', completed_at: Time.current)
      end
    end
  end
end
