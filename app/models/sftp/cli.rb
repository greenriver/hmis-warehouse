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
# Each operation executes as a separate sftp connection using batch mode.
# Password authentication uses sshpass with a temporary file to avoid exposing credentials in process lists.
#
# Sample usage:
#   Sftp::Cli.start('example.com', 'username', password: 'password', skip_verify_host_key: true) do |sftp|
#     sftp.dir.glob('/path/to/directory', '*.csv').each do |file|
#       puts file.name
#     end
#   end
#
# Options:
#   password: - Password for authentication (uses sshpass)
#   port: - Port number (default: 22)
#   keys: - Array of SSH key file paths
#   keys_only: - Only use key authentication
#   skip_verify_host_key: - Skip host key verification (adds -o StrictHostKeyChecking=no)
#   keepalive: - Enable SSH keepalive to prevent disconnection (default: false)
#   keepalive_interval: - Seconds between keepalive messages (default: 60)
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

    # Returns the command that would be executed (for debugging).
    def debug_command
      build_command_parts.join(' ')
    end

    # Removes temporary password file if one was created.
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

    # No-op for compatibility with Net::SFTP (each operation is a separate connection).
    def loop
      # Intentionally empty
    end

    private

    # Executes an sftp command and raises StatusException on failure.
    # Passes commands via stdin instead of batch file to work with sshpass.
    def execute_sftp_command(command)
      stdin_data = "#{Array(command).join("\n")}\nquit\n"
      output, status = Open3.capture2e(*build_command_parts, stdin_data: stdin_data)
      return if status.success?

      error_msg = output.lines.grep(/error|failed|denied|refused/i).join("\n")
      error_msg = output if error_msg.empty?
      raise StatusException, "SFTP command failed: #{command}\n#{error_msg}"
    end

    # Executes an sftp command and returns the output.
    # Used for operations like 'ls' that need to parse the response.
    def execute_sftp_with_output(command)
      stdin_data = "#{Array(command).join("\n")}\nquit\n"
      output, status = Open3.capture2e(*build_command_parts, stdin_data: stdin_data)
      return output if status.success?

      error_msg = output.lines.grep(/error|failed|denied|refused/i).join("\n")
      error_msg = output if error_msg.empty?
      raise StatusException, "SFTP command failed: #{command}\n#{error_msg}"
    end

    # Builds the command parts as an array for safe execution with Open3.
    def build_command_parts
      ensure_password_file if password_auth?

      sftp_parts = ['sftp']
      sftp_parts << '-P' << @options[:port].to_s if @options[:port]
      if key_auth?
        sftp_parts << '-i' << @options[:keys].first
        sftp_parts << '-o' << 'PreferredAuthentications=publickey' if @options[:keys_only]
      end
      sftp_parts.concat(build_ssh_options_parts)
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
      opts << '-o' << 'StrictHostKeyChecking=no' if @options[:skip_verify_host_key]
      if @options[:keepalive]
        interval = @options[:keepalive_interval] || 60
        opts << '-o' << "ServerAliveInterval=#{interval}"
        opts << '-o' << 'ServerAliveCountMax=3'
      end
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

      # Iterates over all entries in a directory, yielding RemoteFile objects.
      def foreach(directory)
        escaped_dir = @connection.send(:escape_path, directory)
        output = @connection.send(:execute_sftp_with_output, "cd #{escaped_dir}\nls -la")
        parse_ls_long_output(output).each { |entry| yield entry }
      end

      # Lists files in the given directory matching the glob pattern.
      # Returns an array of RemoteFile objects with name attribute.
      def glob(directory, pattern)
        escaped_dir = @connection.send(:escape_path, directory)
        output = @connection.send(:execute_sftp_with_output, "cd #{escaped_dir}\nls -1")
        parse_ls_output(output, pattern)
      end

      private

      # Parses the output of 'ls -la' command, preserving the full line as longname.
      def parse_ls_long_output(output)
        output.each_line.filter_map do |line|
          line = line.strip
          next if line.empty? || line.start_with?('sftp>')

          # Extract filename from the end of ls -l output
          # Format: -rw-r--r-- 1 user group 1234 Jan 15 10:30 filename
          match = line.match(/\s(\S+)$/)
          next unless match

          RemoteFile.new(name: match[1], longname: line)
        end
      end

      # Parses the output of 'ls -1' command (one filename per line).
      # Filters files by the glob pattern and creates RemoteFile objects.
      def parse_ls_output(output, pattern)
        pattern_regex = glob_to_regex(pattern)

        output.each_line.filter_map do |line|
          filename = line.strip
          next if filename.empty? || filename.start_with?('sftp>')

          RemoteFile.new(name: filename, longname: filename) if filename.match?(pattern_regex)
        end
      end

      # Converts a glob pattern (e.g., "*.csv") to a regex for matching filenames.
      def glob_to_regex(pattern)
        regex_str = pattern.gsub('.', '\.').gsub('*', '.*').gsub('?', '.')
        Regexp.new("^#{regex_str}$", Regexp::IGNORECASE)
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

    # Represents a file on the remote server.
    RemoteFile = Struct.new(:name, :longname, keyword_init: true)
  end
end
