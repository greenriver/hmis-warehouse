###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'open3'

# Reads and writes .7z archives, which rubyzip cannot open, by running the `7z` binary.
#
# Passwords are passed as their own argument, never interpolated into a command string.
#
# No method raises. The writing methods return whether 7z succeeded; the reading methods
# return nil on failure. Callers decide what a failure means and report it.
class SevenZip
  BIN = '7z'

  DEFAULT_READ_TIMEOUT_SECONDS = 30

  # Writes an archive containing sources. An empty source list is refused, because 7z
  # would otherwise archive the working directory.
  # @param destination [String] path of the archive to write
  # @param sources [Array<String>] files to put in the archive
  # @param password [String, nil] encrypts the archive when given
  # @param level [Integer, nil] compression level, 0-9
  # @return [Boolean] whether 7z succeeded
  def self.create(destination:, sources:, password: nil, level: nil)
    return false if sources.blank?

    args = ['a']
    args << "-mx#{level}" if level
    # A bare -p prompts on a writing call rather than meaning an empty password
    args << "-p#{password}" if password.present?
    system(BIN, *args, destination.to_s, *sources.map(&:to_s))
  end

  # Expands every member of source into destination, discarding the paths inside the
  # archive. Progress goes to the caller's stdout.
  # @return [Boolean] whether 7z succeeded
  def self.extract_all(source:, destination:, password: nil)
    system(BIN, 'e', archive_key_argument(password), "-o#{destination}", source.to_s)
  end

  # Lists the archive without extracting it.
  # @param timeout [Integer] seconds before 7z is killed
  # @return [Array<String>, nil] archive-relative path of every member, or nil when 7z
  #   failed, timed out, or is not installed
  def self.entries(source:, password: nil, timeout: DEFAULT_READ_TIMEOUT_SECONDS)
    output, ok = capture('l', '-ba', '-slt', archive_key_argument(password), source.to_s, timeout: timeout)
    return nil unless ok

    output.lines.filter_map { |line| line[/\APath = (.+?)\s*\z/, 1] }
  end

  # Reads a single member, streamed rather than expanded, and truncated at max_bytes.
  # A member that is not in the archive comes back as an empty string, not nil, because
  # 7z treats it as nothing to extract rather than an error; check .entries to tell those
  # apart.
  # @param entry [String] archive-relative path, as .entries reports it
  # @param max_bytes [Integer] most that will be read back
  # @param timeout [Integer] seconds before 7z is killed
  # @return [String, nil] the member's contents, or nil when 7z failed, timed out, or is
  #   not installed
  def self.read_entry(source:, entry:, max_bytes:, password: nil, timeout: DEFAULT_READ_TIMEOUT_SECONDS)
    output, ok = capture('e', '-so', archive_key_argument(password), source.to_s, entry, max_bytes: max_bytes, timeout: timeout)
    return nil unless ok

    output
  end

  # An empty -p answers 7z's own password prompt, so an encrypted archive fails rather
  # than waiting for input on a reading call.
  private_class_method def self.archive_key_argument(password)
    password.present? ? "-p#{password}" : '-p'
  end

  # Runs 7z with its stdout captured and discards its stderr, killing it if it outlasts
  # timeout. Reading stops at max_bytes, and 7z is closed out rather than left blocked
  # writing the rest.
  # @return [Array(String, Boolean)] stdout and whether 7z succeeded
  private_class_method def self.capture(*args, max_bytes: nil, timeout: nil)
    output = nil
    Open3.popen2(BIN, *args, err: File::NULL) do |stdin, stdout, wait_thread|
      stdin.close
      # Kills 7z at the deadline, which closes stdout and so also ends a read that is
      # still waiting on it.
      watchdog = timeout && Thread.new do
        unless wait_thread.join(timeout)
          begin
            Process.kill('KILL', wait_thread.pid)
          rescue Errno::ESRCH
            nil
          end
        end
      end
      output = max_bytes ? stdout.read(max_bytes) : stdout.read
      stdout.close
      watchdog&.join

      return [output.to_s, false] unless wait_thread.value.success?
    end
    [output.to_s, true]
  rescue Errno::ENOENT, Errno::EPIPE, Errno::ESRCH
    ['', false]
  end
end
