###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'English'
require 'shellwords'
require 'open3'

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
      @batch_files = []
    end

    # Removes temporary password file and batch files if any were created.
    def cleanup
      if @password_file
        File.unlink(@password_file.path) if File.exist?(@password_file.path)
        @password_file = nil
      end
      @batch_files.each do |batch_file|
        File.unlink(batch_file.path) if File.exist?(batch_file.path)
      end
      @batch_files.clear
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
      cmd_parts = build_sftp_command_parts(command)
      output, status = Open3.capture2e(*cmd_parts)
      return if status.success?

      error_msg = output.lines.grep(/error|failed|denied|refused/i).join("\n")
      error_msg = output if error_msg.empty?
      raise StatusException, "SFTP command failed: #{command}\n#{error_msg}"
    end

    # Executes an sftp command and returns the output.
    # Used for operations like 'ls' that need to parse the response.
    def execute_sftp_with_output(command)
      cmd_parts = build_sftp_command_parts(command)
      output, status = Open3.capture2e(*cmd_parts)
      return output if status.success?

      error_msg = output.lines.grep(/error|failed|denied|refused/i).join("\n")
      error_msg = output if error_msg.empty?
      raise StatusException, "SFTP command failed: #{command}\n#{error_msg}"
    end

    # Builds the command parts as an array for safe execution with Open3.
    # Uses a temporary batch file to pass commands to sftp, which is safer than heredoc.
    # The batch file is tracked and cleaned up in the cleanup method.
    def build_sftp_command_parts(sftp_commands)
      commands = Array(sftp_commands).join("\n")
      batch_file = Tempfile.new('sftp_batch')
      batch_file.write("#{commands}\nquit\n")
      batch_file.close
      File.chmod(0o600, batch_file.path)
      @batch_files << batch_file

      build_base_command_parts(include_batch_file: batch_file.path)
    end

    # Builds the base command parts as an array for safe execution.
    def build_base_command_parts(include_batch_file: nil)
      ensure_password_file if password_auth?

      sftp_parts = ['sftp']
      sftp_parts << '-P' << @options[:port].to_s if @options[:port]
      if key_auth?
        sftp_parts << '-i' << @options[:keys].first
        sftp_parts << '-o' << 'PreferredAuthentications=publickey' if @options[:keys_only]
      end
      sftp_parts.concat(build_ssh_options_parts)
      # -b flag must come before the destination
      sftp_parts << '-b' << include_batch_file if include_batch_file
      sftp_parts << "#{@username}@#{@host}"

      if password_auth?
        ['sshpass', '-f', @password_file.path] + sftp_parts
      else
        sftp_parts
      end
    end

    # Builds SSH option flags as separate -o flag=value pairs for the sftp command.
    def build_ssh_options_parts
      opts = []
      opts << '-o' << 'PasswordAuthentication=yes' if password_auth?
      opts << '-o' << 'StrictHostKeyChecking=no' if @options[:skip_verify_host_key]
      opts
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

    # Escapes special characters in file paths for safe use in SFTP batch commands.
    # Note: This is for SFTP command escaping, not shell escaping.
    def escape_path(path)
      Shellwords.escape(path.to_s)
    end

    # Proxy for directory operations, providing Net::SFTP-compatible API.
    class DirProxy
      def initialize(connection)
        @connection = connection
      end

      # Lists files in the given directory matching the glob pattern.
      # Returns an array of RemoteFile objects with name, size, and mtime attributes.
      # Uses 'cd' followed by 'ls -l' to ensure we're listing the correct directory.
      def glob(directory, pattern)
        escaped_dir = @connection.send(:escape_path, directory)
        output = @connection.send(:execute_sftp_with_output, "cd #{escaped_dir}\nls -l")
        parse_ls_output(output, directory, pattern)
      end

      private

      # Parses the output of 'ls -l' command, extracting file metadata.
      # Filters files by the glob pattern and creates RemoteFile objects with attributes.
      # Note: ls -l returns modification time (mtime), not creation time.
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
            mtime: parse_date(date_str),
          )
        end

        files
      end

      # Converts a glob pattern (e.g., "*.csv") to a regex for matching filenames.
      def glob_to_regex(pattern)
        regex_str = pattern.gsub('.', '\.').gsub('*', '.*').gsub('?', '.')
        Regexp.new("^#{regex_str}$", Regexp::IGNORECASE)
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
            Time.strptime("#{date_str} #{Time.current.year}", '%b %d %H:%M %Y')
          rescue StandardError
            nil
          end
          parsed ||= begin
            Time.strptime("#{date_str} #{Time.current.year}", '%b %d %Y')
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
    # Provides an 'attributes' method that returns file metadata.
    # Note: mtime (modification time) is what ls -l provides
    # for compatibility with Net::SFTP API usage in existing code.
    RemoteFile = Struct.new(:name, :directory, :size, :mtime, keyword_init: true) do
      def attributes
        @attributes ||= Attributes.new(mtime)
      end
    end

    # Container for file attributes, matching Net::SFTP::Attributes API.
    Attributes = Struct.new(:mtime, keyword_init: true)
  end
end
