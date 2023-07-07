###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Exporters
  class ClientExportUploader
    delegate :username, :host, :path, :password, :port, to: :credentials

    attr_accessor :io_streams, :filename

    def initialize(io_streams: [], date: Date.today)
      self.io_streams = io_streams
      self.filename = date.strftime('%Y-%m-%d-clients.zip')

      require 'net/sftp'
    end

    def run!
      Rails.logger.info "Sftping to #{username}@#{host}"
      args = { password: password, verbose: :error, port: port || 22 }
      Net::SFTP.start(host, username, args) do |sftp|
        zipped_contents = zipped_io_stream.string

        Rails.logger.info "Uploading #{filename} to #{path}"

        sftp.file.open("#{path}/#{filename}", 'w') do |f|
          f.write(zipped_contents)
        end
      end
    rescue Net::SFTP::StatusException, Errno::ECONNRESET, SocketError => e
      # FIXME: potential point for doing retries
      Rails.logger.fatal "Cannot upload. #{e.message}"
      raise e
    end

    def self.can_run?
      !!new.send(:credentials)
    end

    private

    def zipped_io_stream
      Rails.logger.info "Compressing #{filename}"

      Zip::OutputStream.write_buffer do |zio|
        io_streams.each do |stream|
          zio.put_next_entry(stream.name)
          stream.io.rewind # Just in case
          Rails.logger.info "Adding #{stream.name}"
          zio.write stream.io.read
        end
      end
    end

    def credentials
      @credentials ||= GrdaWarehouse::RemoteCredentials::Sftp.find_by(slug: 'ac_hmis_client_export')
    end
  end
end
