###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
  class UpdateClientLookupViaMail < UpdateClientLookup
    include TsqlImport
    attr_accessor :logger

    # Fetch client mapping from Gmail and replace all records for each data source with
    # new values
    def run!
      return unless GrdaWarehouse::Config.get(:eto_api_available)

      self.logger = Rails.logger
      logger.info 'Fetching client mappings from ETO'
      @gmail = connect_to_gmail
      unless @gmail.logged_in?
        logger.error 'Could not connect to Gmail, giving up'
        return
      end
      @data_sources.each do |ds_id, subject|
        logger.info "Fetching client mapping for data source: #{ds_id}, looking for email with subject #{subject}..."
        @attachment = fetch_most_recent_mapping_file(ds_id, subject)
        if @attachment.present?
          @csv = parse_csv_from_file(@attachment.body.decoded)
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

    protected def connect_to_gmail
      credentials = YAML.load(ERB.new(File.read("#{Rails.root}/config/mail_account.yml")).result)[Rails.env] # rubocop:disable Security/YAMLLoad
      Gmail.connect(credentials['user'], credentials['pass'])
    end

    protected def fetch_most_recent_mapping_file(_ds_id, subject)
      messages = @gmail.inbox.emails(after: Date.yesterday, subject: subject)
      unless messages.present?
        logger.warn 'No recent updates found...giving up'
        return nil
      end
      message = messages.max_by(&:uid)
      attachment = message.attachments.first
      # unless attachment.content_type.split(';').first == 'text/csv'
      #   logger.warn "Attachment is not a CSV #{attachment.inspect}"
      #   return nil
      # end
      attachment
    end
  end
end
