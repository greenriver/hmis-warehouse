###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Exporters
  class DataWarehouseUploader
    delegate :username, :host, :path, :password, :port, to: :credentials

    attr_accessor :io_streams, :filename, :pre_zipped_data

    def initialize(io_streams: [], pre_zipped_data: nil, date: Date.today, filename_format: 'file.zip')
      self.io_streams = io_streams
      self.pre_zipped_data = pre_zipped_data

      self.filename = date.strftime(filename_format)

      raise 'You can only pass in an array of uncompressed I/O streams or the zipped content' unless io_streams.present? ^ pre_zipped_data.present?

      require 'net/sftp'
    end

    def run!
      Rails.logger.info "Sftping to #{username}@#{host}"
      args = { password: password, verbose: :error, port: port || 22 }
      Net::SFTP.start(host, username, args) do |sftp|
        Rails.logger.info "Uploading #{zipped_contents.length} bytes to #{path}/#{filename}"

        sftp.remove("#{path}/#{filename}")

        sftp.file.open("#{path}/#{filename}", 'w') do |f|
          0.upto(zipped_contents.length / 1024 + 1).each do |i|
            chunk = zipped_contents[i * 1024, 1024]

            break if chunk.nil?

            f.write(chunk)
            Rails.logger.info "Wrote about #{i} kilobytes" if (i % 20).zero?
          end
        end
      end
    rescue Net::SFTP::StatusException, Errno::ECONNRESET, SocketError => e
      # FIXME: potential point for doing retries
      Rails.logger.fatal "Cannot upload. #{e.message}"
      raise e
    end

    def self.can_run?
      !!new(pre_zipped_data: 'nothing').send(:credentials)
    end

    private

    def zipped_contents
      @zipped_contents ||= io_streams.present? ? zipped_io_stream.string : pre_zipped_data
    end

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
      @credentials ||= GrdaWarehouse::RemoteCredentials::Sftp.active.find_by(slug: 'ac_data_warehouse_sftp_server')
    end
  end
end
