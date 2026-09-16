###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'pty'
require 'expect'

# Drives the `zipcloak` binary, which takes its password from the controlling
# terminal rather than an argument, so it has to be run under a pty.
#
# The password is written to the child as terminal input. It never reaches a
# shell command line or a generated script, so it needs no escaping and cannot
# be used to inject commands.
class ZipCloak
  class Error < RuntimeError; end

  # Long enough to cover a large archive being rewritten between prompts,
  # short enough that a wedged child doesn't hold the job forever.
  PROMPT_TIMEOUT = 5.minutes.to_i

  # zipcloak accepts a password up to this length and rejects anything longer.
  MAX_PASSWORD_LENGTH = 80
  TOO_LONG = 'line too long'

  # zipcloak asks for the password, then asks again to verify it.
  def self.encrypt(source:, destination:, password:)
    new(password: password).run(['--output-file', destination.to_s, source.to_s], prompts: 2)
  end

  # Decryption only asks once; a wrong password copies the entries through
  # unchanged rather than failing.
  def self.decrypt(source:, destination:, password:)
    new(password: password).run(['-d', '--output-file', destination.to_s, source.to_s], prompts: 1)
  end

  def initialize(password:)
    @password = password
  end

  def run(args, prompts:)
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
      # zipcloak re-prompts rather than exiting when the password is too long,
      # so it would otherwise wait for one it will never be sent.
      abort_child(pid, "the password is longer than zipcloak's #{MAX_PASSWORD_LENGTH} character limit") if match.first.include?(TOO_LONG)

      # The pty is in canonical mode, so the child reads the line on the return.
      writer.print("#{@password}\r")
      writer.flush
    end
    reader.read
  rescue Errno::EIO
    # A pty raises EIO rather than returning EOF once the child is gone, which
    # is how zipcloak bailing out before or between the prompts arrives here.
    # The exit status checked above says why it did.
    nil
  end

  private def abort_child(pid, message)
    Process.kill('TERM', pid)
    Process.wait(pid)
    raise Error, message
  end
end
