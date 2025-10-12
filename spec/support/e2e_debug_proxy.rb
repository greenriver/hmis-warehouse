# frozen_string_literal: true

require 'socket'

# Exposes Chromium's loopback-only DevTools socket on a host-accessible port so
# Capybara + Cuprite can be inspected from outside the container. Chromium 130+
# ignores the legacy remote-debugging-address flag, so we bridge traffic using a
# lightweight TCP proxy instead of depending on additional system services.

module E2eTests
  module DebugProxy
    class << self
      def start(remote_port:, proxy_port:)
        return unless remote_port
        return if proxy_port.nil? || proxy_port == remote_port

        mutex.synchronize do
          return if active_proxy?(remote_port, proxy_port)

          stop_proxy

          @proxy_thread = Thread.new do
            Thread.current.report_on_exception = false
            run_proxy(remote_port, proxy_port)
          end

          @proxy_thread.abort_on_exception = false
          @active_remote_port = remote_port
          @active_proxy_port = proxy_port
        end
      end

      def stop
        mutex.synchronize do
          stop_proxy
        end
      end

      private

      def active_proxy?(remote_port, proxy_port)
        @proxy_thread&.alive? &&
          @active_remote_port == remote_port &&
          @active_proxy_port == proxy_port
      end

      def run_proxy(remote_port, proxy_port)
        server = TCPServer.new('0.0.0.0', proxy_port)
        @server = server
        Kernel.warn("Cuprite debug proxy forwarding 0.0.0.0:#{proxy_port} -> 127.0.0.1:#{remote_port}")

        loop do
          client = server.accept
          spawn_proxy_session(client, remote_port)
        end
      rescue Errno::EADDRINUSE => e
        Kernel.warn("Cuprite debug proxy could not bind: #{e.message}")
      rescue StandardError => e
        Kernel.warn("Cuprite debug proxy halted: #{e.class}: #{e.message}")
      ensure
        safe_close(@server)
        @server = nil
      end

      def spawn_proxy_session(client_socket, remote_port)
        Thread.new do
          Thread.current.report_on_exception = false

          begin
            target_socket = TCPSocket.new('127.0.0.1', remote_port)
          rescue StandardError => e
            Kernel.warn("Cuprite debug proxy connection failed: #{e.class}: #{e.message}")
            safe_close(client_socket)
            next
          end

          forward_io(client_socket, target_socket)
        end
      end

      def forward_io(client_socket, target_socket)
        threads = []
        threads << Thread.new { copy_stream(client_socket, target_socket) }
        threads << Thread.new { copy_stream(target_socket, client_socket) }
        threads.each { |t| t.report_on_exception = false }
        threads.each(&:join)
      ensure
        safe_close(client_socket)
        safe_close(target_socket)
      end

      def copy_stream(source, destination)
        IO.copy_stream(source, destination)
      rescue IOError, SystemCallError
        # ignore
      ensure
        begin
          destination.flush
        rescue IOError, SystemCallError
          # ignore
        end
      end

      def safe_close(socket)
        socket&.close unless socket&.closed?
      rescue IOError, SystemCallError
        # ignore
      end

      def stop_proxy
        safe_close(@server)
        @proxy_thread&.kill
        @proxy_thread = nil
        @active_remote_port = nil
        @active_proxy_port = nil
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
