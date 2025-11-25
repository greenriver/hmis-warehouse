###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'English'

# Wrapper around the system's sftp CLI client that provides a Net::SFTP-compatible API.
# Each operation executes as a separate sftp connection using batch mode (-b -) with heredoc input.
# Password authentication uses sshpass with a temporary file to avoid exposing credentials in process lists.
# Sample usage:
# Sftp::Cli.start('example.com', 'username', password: 'password') do |sftp|
#   sftp.dir.glob('path/to/directory', '*.csv') do |file|
#     puts file.name
#   end
# end
module Sftp
  class Cli
    class Error < StandardError; end
    class StatusException < Error; end

    # Creates a new SFTP connection and yields it to the block.
    # Automatically cleans up temporary password files on exit.
    def self.start(host, username, **options)
      connection = new(host, username, **options)
      yield connection
    ensure
      connection&.cleanup
    end

    def initialize(host, username, **options)
      @host = host
      @username = username
      @options = options
      @password_file = nil
    end

    # Removes temporary password file if one was created for authentication.
    def cleanup
      return unless @password_file

      File.unlink(@password_file.path) if File.exist?(@password_file.path)
      @password_file = nil
    end

    # Returns a proxy object for directory operations (e.g., dir.glob).
    def dir
      @dir ||= DirProxy.new(self)
    end

    # Downloads a file from the remote server to a local path using sftp 'get' command.
    def download!(remote_path, local_path)
      execute_sftp_command("get #{escape_path(remote_path)} #{escape_path(local_path)}")
    end

    # Uploads a file from a local path to the remote server using sftp 'put' command.
    def upload!(local_path, remote_path)
      execute_sftp_command("put #{escape_path(local_path)} #{escape_path(remote_path)}")
    end

    # Removes a file from the remote server using sftp 'rm' command.
    def remove(remote_path)
      execute_sftp_command("rm #{escape_path(remote_path)}")
    end

    # Returns a proxy object for file operations (e.g., file.open).
    def file
      @file ||= FileProxy.new(self)
    end

    private

    # Executes an sftp command and raises StatusException on failure.
    # Captures both stdout and stderr, filtering error messages for clearer exceptions.
    def execute_sftp_command(command)
      cmd = build_sftp_command(command)
      output = `#{cmd} 2>&1`
      status = $CHILD_STATUS.exitstatus
      return if status.zero?

      error_msg = output.lines.grep(/error|failed|denied|refused/i).join("\n")
      error_msg = output if error_msg.empty?
      raise StatusException, "SFTP command failed: #{command}\n#{error_msg}"
    end

    # Executes an sftp command and returns the output.
    # Used for operations like 'ls' that need to parse the response.
    def execute_sftp_with_output(command)
      cmd = build_sftp_command(command)
      output = `#{cmd} 2>&1`
      status = $CHILD_STATUS.exitstatus
      return output if status.zero?

      error_msg = output.lines.grep(/error|failed|denied|refused/i).join("\n")
      error_msg = output if error_msg.empty?
      raise StatusException, "SFTP command failed: #{command}\n#{error_msg}"
    end

    # Builds the complete shell command that executes sftp in batch mode.
    # Uses heredoc (<<EOF) to pass commands to sftp via stdin, with -b - flag for batch mode.
    def build_sftp_command(sftp_commands)
      base_cmd = build_base_command
      commands = Array(sftp_commands).join("\n")
      "#{base_cmd} -b - <<EOF\n#{commands}\nquit\nEOF"
    end

    # Constructs the base sftp command with authentication and connection options.
    # Prepends sshpass if password authentication is needed, adds port/key options as required.
    def build_base_command
      ensure_password_file if password_auth?

      parts = []
      parts << 'sshpass' << %(-f #{@password_file.path}) if password_auth?
      parts << 'sftp'
      parts << %(-P #{@options[:port]}) if @options[:port]
      if key_auth?
        parts << %(-i #{@options[:keys].first})
        parts << '-o PreferredAuthentications=publickey' if @options[:keys_only]
      end
      parts << build_ssh_options
      parts << %(#{@username}@#{@host})

      parts.join(' ')
    end

    # Builds SSH option flags for the sftp command.
    def build_ssh_options
      opts = []
      opts << '-o PasswordAuthentication=yes' if password_auth?
      opts << '-o StrictHostKeyChecking=no' if @options[:append_all_supported_algorithms]
      opts.join(' ')
    end

    # Returns true if password authentication should be used.
    def password_auth?
      @options[:password].present? || @options[:auth_methods]&.include?('password')
    end

    # Returns true if SSH key authentication should be used.
    def key_auth?
      @options[:keys].present? && @options[:keys].any?
    end

    # Creates a temporary file with restricted permissions (0600) containing the password.
    # This file is used by sshpass to avoid exposing the password in process lists or command history.
    def ensure_password_file
      return if @password_file && File.exist?(@password_file.path)

      @password_file = Tempfile.new('sftp_password')
      @password_file.write(@options[:password] || '')
      @password_file.close
      File.chmod(0o600, @password_file.path)
    end

    # Escapes special characters in file paths for safe use in shell commands.
    def escape_path(path)
      path.to_s.gsub(' ', '\\ ').gsub('(', '\\(').gsub(')', '\\)').gsub('[', '\\[').gsub(']', '\\]').gsub('*', '\\*').gsub('?', '\\?')
    end

    # Proxy for directory operations, providing Net::SFTP-compatible API.
    class DirProxy
      def initialize(connection)
        @connection = connection
      end

      # Lists files in the given directory matching the glob pattern.
      # Returns an array of RemoteFile objects with name, size, and createtime attributes.
      # Uses 'cd' followed by 'ls -l' to ensure we're listing the correct directory.
      def glob(directory, pattern)
        escaped_dir = @connection.send(:escape_path, directory)
        output = @connection.send(:execute_sftp_with_output, %(cd #{escaped_dir}\nls -l))
        parse_ls_output(output, directory, pattern)
      end

      private

      # Parses the output of 'ls -l' command, extracting file metadata.
      # Filters files by the glob pattern and creates RemoteFile objects with attributes.
      def parse_ls_output(output, directory, pattern)
        files = []
        pattern_regex = glob_to_regex(pattern)

        output.each_line do |line|
          line = line.strip
          next if line.start_with?('sftp>') || line.empty?
          next unless line.match?(/^[-d]/)

          # Parse ls -l format: permissions links owner group size date time name
          # Example: -rw-r--r-- 1 user group 1234 Jan 15 10:30 file.csv
          # Or:      -rw-r--r-- 1 user group 1234 Jan 15 2024 file.csv
          match = line.match(/^[-d](?:[rwx-]{9})\s+\d+\s+\S+\s+\S+\s+(\d+)\s+(\w{3}\s+\d{1,2}\s+[\d:]+|\w{3}\s+\d{1,2}\s+\d{4})\s+(.+)$/)
          next unless match

          size, date_str, filename = match.captures
          filename = filename.strip
          next unless filename.match?(pattern_regex)

          files << RemoteFile.new(
            name: filename,
            directory: directory,
            size: size.to_i,
            createtime: parse_date(date_str),
          )
        end

        files
      end

      # Converts a glob pattern (e.g., "*.csv") to a regex for matching filenames.
      def glob_to_regex(pattern)
        regex_str = pattern.gsub('.', '\.').gsub('*', '.*').gsub('?', '.')
        Regexp.new(%(^#{regex_str}$), Regexp::IGNORECASE)
      end

      # Parses date strings from ls -l output.
      # Handles both formats: "Jan 15 10:30" (current year) and "Jan 15 2024" (past year).
      def parse_date(date_str)
        date_str = date_str.strip
        if date_str.match?(/\d{4}$/)
          begin
            Time.strptime(date_str, '%b %d %Y')
          rescue StandardError
            Time.current
          end
        else
          # For dates without year, assume current year
          parsed = begin
            Time.strptime(%(#{date_str} #{Time.current.year}), '%b %d %H:%M %Y')
          rescue StandardError
            nil
          end
          parsed ||= begin
            Time.strptime(%(#{date_str} #{Time.current.year}), '%b %d %Y')
          rescue StandardError
            nil
          end
          parsed || Time.current
        end
      end
    end

    # Proxy for file operations, providing Net::SFTP-compatible API.
    class FileProxy
      def initialize(connection)
        @connection = connection
      end

      # Opens a file on the remote server for writing.
      # For write mode, streams data to a temporary file first, then uploads it.
      # This allows the block to write chunks incrementally before the upload happens.
      def open(remote_path, mode = 'r')
        raise NotImplementedError, 'Read mode not yet implemented' unless mode == 'w'

        file = Tempfile.new('sftp_upload')
        begin
          yield file
          file.flush
          file.close
          @connection.upload!(file.path, remote_path)
        ensure
          file.unlink if file.path
        end
      end
    end

    # Represents a file on the remote server with metadata.
    # Provides an 'attributes' method that returns file metadata like createtime.
    RemoteFile = Struct.new(:name, :directory, :size, :createtime, keyword_init: true) do
      def attributes
        @attributes ||= Attributes.new(createtime)
      end
    end

    # Container for file attributes, matching Net::SFTP::Attributes API.
    Attributes = Struct.new(:createtime, keyword_init: true)
  end
end
