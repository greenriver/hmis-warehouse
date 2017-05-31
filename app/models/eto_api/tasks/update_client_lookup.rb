require 'gmail'
require 'csv'
# Fix for bug in imap date conversion
# https://github.com/gmailgem/gmail/issues/228
class Object
  def to_imap_date
    date = respond_to?(:utc) ? utc.to_s : to_s
    Date.parse(date).strftime('%d-%b-%Y')
  end
end
module EtoApi::Tasks
  class UpdateClientLookup
    include TsqlImport
    attr_accessor :logger
    def initialize()
      # map data source to subject line
      @data_sources = [[1,  '[Client GUID Table DND]'], [3, '[Client GUID Table BPHC]']]
      @expected_headers = ["Site Name", "Site ID Coded", "Participant Enterprise Identifier", "Participant Site Identifier", "Contact Date"]
      @headers = [:site_id_in_data_source, :warehouse_id, :id_in_data_source, :last_contact, :data_source_id, :client_id]
    end

    # Fetch client mapping from Gmail and replace all records for each data source with 
    # new values
    def run!
      self.logger = Rails.logger
      logger.info "Fetching client mappings from ETO"
      @gmail = connect_to_gmail
      unless @gmail.logged_in?
        logger.error "Could not connect to Gmail, giving up"
        return
      end
      @data_sources.each do |ds_id, subject|
        logger.info "Fetching client mapping for data source: #{ds_id}, looking for email with subject #{subject}..."
        @attachment = fetch_most_recent_mapping_file(ds_id, subject)
        if @attachment.present?
          updated_rows = update_client_lookup(ds_id)
          logger.info "Found #{updated_rows} clients to update ..."
          cleaned_clients = clean_hmis_clients
          logger.info "Removed #{cleaned_clients} hmis clients no longer referenced ..."
          cleaned_forms = clean_hmis_forms
          logger.info "Removed #{cleaned_forms} hmis forms attached to clients no longer referenced ..."
        end
        logger.info "...client mapping for Data Source ID: #{ds_id} complete"
      end
      @gmail.logout
    end

    private def connect_to_gmail
      credentials = Rails.application.config_for(:mail_account)['dnd']
      Gmail.connect(credentials['user'], credentials['pass'])
    end

    private def fetch_most_recent_mapping_file ds_id, subject
      messages = @gmail.inbox.emails(after: Date.yesterday, subject: subject)
      unless messages.present?
        logger.warn "No recent updates found...giving up"
        return nil
      end
      message = messages.sort_by(&:uid).last
      attachment = message.attachments.first
      # unless attachment.content_type.split(';').first == 'text/csv'
      #   logger.warn "Attachment is not a CSV #{attachment.inspect}"
      #   return nil
      # end
      attachment
    end

    # Very basically validate the structure
    # Pull off the Site name (first column)
    # Add the data source id and client_id at the end
    # Delete any entries for the current data source
    # Stream new file into the warehouse
    private def update_client_lookup ds_id
      @csv = CSV.parse(@attachment.body.decoded)
      unless @csv.first == @expected_headers
        logger.warn "CSV file does not appear valid, found:"
        logger.warn @csv.first.inspect
        logger.warn "expected:"
        logger.warn @expected_headers.inspect
        return nil
      end
      @csv = @csv.map! do |row|
        if row.length == @expected_headers.length
          site_name, site_id, guid, client_site_id, last_contact = row
          if guid.present?
            # remove the nasty {} that shouldn't be there, but somehow sneak back in
            guid = guid.gsub('{', '').gsub('}', '')
            
            # attempt to find the client associated with this id for future joining
            client_id = client_id_from_personal_id(row[2].gsub('-',''))
            clean = [site_id, guid, client_site_id, last_contact, ds_id, client_id]
          end
        end
      end.compact
      GrdaWarehouse::ApiClientDataSourceId.transaction do
        GrdaWarehouse::ApiClientDataSourceId.where(data_source_id: ds_id).delete_all
        insert_batch(GrdaWarehouse::ApiClientDataSourceId, @headers, @csv.drop(1), transaction: false)
      end
      @csv.size
    end

    private def clean_hmis_clients
      GrdaWarehouse::HmisClient.
        where.not(
          client_id: GrdaWarehouse::ApiClientDataSourceId.
            where.not(client_id: nil).
            select(:client_id).distinct
        ).delete_all
    end

    private def clean_hmis_forms
      GrdaWarehouse::HmisForm.
        where.not(
          client_id: GrdaWarehouse::ApiClientDataSourceId.
            where.not(client_id: nil).
            select(:client_id).distinct
        ).delete_all
    end

    private def client_source
      GrdaWarehouse::Hud::Client.source
    end

    private def client_id_from_personal_id personal_id
      @client_ids ||= client_source.pluck(:PersonalID, :id).to_h
      @client_ids[personal_id]
    end
  end
end
