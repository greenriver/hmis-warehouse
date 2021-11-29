###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'net/sftp'

module Health
  class ScheduledDocuments::Base < HealthBase
    self.table_name = :scheduled_documents

    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    validates :name, presence: true

    scope :active, -> do
      where(active: true)
    end

    scope :inactive, -> do
      where(active: false)
    end

    # To be implemented in subclasses:

    # Generate and deliver the scheduled document
    def deliver(_user)
      raise 'Not implemented'
    end

    # Should the scheduled document be delivered at the current time?
    # The processor will periodically poll the defined scheduled documents, and invoke 'deliver' on
    # the ones that return true to this query.
    def should_be_delivered?
      false
    end

    def available_protocols
      {
        sftp: 'SFTP',
      }.invert
    end

    def send_file(file_name:, data:)
      case protocol
      when 'sftp'
        send_via_sftp(file_name: file_name, data: data)
      else
        raise 'Unknown protocol'
      end

      true # File was sent
    end

    def send_via_sftp(file_name:, data:)
      Net::SFTP.start(hostname, username, password: password, port: (port.presence || 22)) do |sftp|
        sftp.file.open(File.join(file_path, file_name), 'w') do |f|
          f.puts data
        end
      end
    end

    # The names of the parameters that should be added to the permitted parameters list for a scheduled document
    # class
    def params
      []
    end
  end
end
