###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'pty'
require 'expect'
require 'zip'

# Drives the `zipcloak` binary, which takes its password from the controlling
# terminal rather than an argument, so it has to be run under a pty.
class ZipCloak
  class Error < RuntimeError; end

  # Long enough to cover a large archive being rewritten between prompts,
  # short enough that a wedged child doesn't hold the job forever.
  PROMPT_TIMEOUT = 5.minutes.to_i

  MAX_PASSWORD_LENGTH = 80
  TOO_LONG_MESSAGE = 'line too long'

  # The pty below runs in canonical mode, so the line discipline acts on control
  # characters before zipcloak ever reads them: erase and kill rewrite the line,
  # EOF submits it early, interrupt kills the child. A six character password
  # holding a kill and an erase arrives as one character. Encryption would then
  # succeed under a password that is not the one on record, since both prompts
  # are rewritten alike and the verify prompt still matches.
  CONTROL_CHARACTERS = /[[:cntrl:]]/

  def self.encrypt(source:, destination:, password:)
    new(password: password).encrypt(source: source, destination: destination)
  end

  def self.decrypt(source:, destination:, password:)
    new(password: password).decrypt(source: source, destination: destination)
  end

  def initialize(password:)
    raise Error, 'the password cannot contain control characters, including a line break' if password.to_s.match?(CONTROL_CHARACTERS)

    @password = password
  end

  # zipcloak asks for the password, then asks again to verify it.
  def encrypt(source:, destination:)
    run(['--output-file', destination.to_s, source.to_s], prompts: 2)
  end

  # Decryption asks once. A wrong password is not an error to zipcloak: it copies
  # the entries through still encrypted and exits 0.
  def decrypt(source:, destination:)
    run(['-d', '--output-file', destination.to_s, source.to_s], prompts: 1)
    raise Error, 'zipcloak left the archive encrypted, so the password is wrong' if encrypted_entries?(destination)

    true
  end

  private def encrypted_entries?(path)
    Zip::File.open(path.to_s) { |zip| zip.any?(&:encrypted?) }
  end

  private def run(args, prompts:)
    status = nil
    PTY.spawn('zipcloak', *args) do |reader, writer, pid|
      answer_prompts(reader, writer, pid, prompts)
      _, status = Process.wait2(pid)
    end
    raise Error, "zipcloak exited #{status&.exitstatus.inspect}" unless status&.success?

    true
  end

  private def answer_prompts(reader, writer, pid, prompts)
    prompts.times do
      match = reader.expect(/password: /, PROMPT_TIMEOUT)
      abort_child(pid, 'timed out waiting for the zipcloak password prompt') if match.nil?
      check_password_length(pid, match.first)

      # The pty is in canonical mode, so the child reads the line on the return.
      writer.print("#{@password}\r")
      writer.flush
    end
    wait_for_exit(reader, pid)
  rescue Errno::EIO
    # A pty raises EIO rather than returning EOF once the child is gone, so zipcloak
    # exiting before or between the prompts arrives here.
    nil
  end

  # zipcloak re-prompts rather than exiting on a password it considers too long, so
  # reading to EOF here would block forever. The decrypt run answers a single prompt,
  # so this loop is the only place that re-prompt is seen.
  private def wait_for_exit(reader, pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + PROMPT_TIMEOUT
    buffer = +''
    loop do
      check_password_length(pid, buffer)
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      abort_child(pid, 'timed out waiting for zipcloak to finish') if remaining <= 0 || IO.select([reader], nil, nil, remaining).nil?

      chunk = reader.read_nonblock(4096, exception: false)
      break if chunk.nil? # the child closed the pty

      buffer << chunk unless chunk == :wait_readable
    end
  end

  private def check_password_length(pid, output)
    return unless output.include?(TOO_LONG_MESSAGE)

    abort_child(pid, "the password is longer than zipcloak's #{MAX_PASSWORD_LENGTH} character limit")
  end

  private def abort_child(pid, message)
    Process.kill('TERM', pid)
    Process.wait(pid)
    raise Error, message
  end
end
