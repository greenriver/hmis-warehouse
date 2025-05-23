###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :test do
  desc 'Test generating an Exception'
  task :exception, [] => [:environment] do |_t, _args|
    raise StandardError, 'An Exception has been raised from within a Rake task.'
  end

  desc 'Test Sentry'
  task :sentry, [] => [:environment] do |_t, _args|
    include NotifierConfig
    setup_notifier('SentryTest')

    # The sleeps make it easier to see which steps trigger a 'sending envelope to Sentry' log message

    puts 'Sentry.capture_exception'
    Sentry.capture_exception(StandardError.new("Testing Sentry.capture_exception from #{Rails.env} for hmis-warehouse"))
    sleep 1

    puts 'Sentry.capture_message'
    Sentry.capture_message("Testing Sentry.capture_message from #{Rails.env} for hmis-warehouse")
    sleep 1

    puts 'Sentry.capture_exception_with_info'
    Sentry.capture_exception_with_info(
      StandardError.new("Testing Sentry.capture_exception_with_info from #{Rails.env} for hmis-warehouse"),
      'Testing custom error message',
      { with: 'data' },
    )
    sleep 1

    puts 'Sentry.capture_exception_with_info_no_exception'
    Sentry.capture_exception_with_info(
      StandardError.new("Testing Sentry.capture_exception_with_info_no_exception from #{Rails.env} for hmis-warehouse"),
      'Testing custom error message',
      { info: 'info' },
    )
    sleep 1

    puts '@notifier.ping with exception (Sentry)'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry with data'),
        info: { with: 'data' },
      },
    )
    sleep 1

    puts '@notifier.ping with exception (Sentry), but no info'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry without data'),
      },
    )
    sleep 1

    puts '@notifier.ping with exception (Sentry), but nil info'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry with nil data'),
        info: nil,
      },
    )
    sleep 1

    puts '@notifier.ping normal (Slack)'
    @notifier.ping('Testing .ping polymorphism - this should go to Slack')
  end

  desc 'Evaluate all TodoOrDie calls in the codebase'
  task todo_or_die: :environment do
    require 'parser/current'

    # Find all Ruby files in the application
    ruby_files = Dir.glob('{app,config,lib,drivers}/**/*.rb')

    puts "Found #{ruby_files.length} Ruby files to check"

    # Track all TodoOrDie calls
    todo_calls = []
    overdue_todos = []

    ruby_files.each do |file|
      # Read the file content
      content = File.read(file)
      # Parse the file
      ast = Parser::CurrentRuby.parse(content)

      # Find all TodoOrDie calls
      find_todo_calls(ast, file, content, todo_calls)
    rescue Parser::SyntaxError => e
      puts "Syntax error in #{file}: #{e.message}"
    rescue StandardError => e
      puts "Error processing #{file}: #{e.message}"
    end

    puts "\nFound #{todo_calls.length} TodoOrDie calls"

    # Create a temporary file with all TodoOrDie calls
    require 'tempfile'
    temp_file = Tempfile.new(['todo_or_die_calls', '.rb'])
    begin
      # Write each TodoOrDie call to the temp file
      todo_calls.each do |call|
        temp_file.puts "# #{call[:file]}:#{call[:line]}"
        temp_file.puts call[:code]
        temp_file.puts
      end
      temp_file.close

      # Load the temporary file to evaluate all TodoOrDie calls
      load temp_file.path
    rescue TodoOrDie::OverdueTodo => e
      # Handle TodoOrDie errors specifically
      message = "Overdue TODO found\nMessage: #{e.message}"
      puts "\n#{message}"
      overdue_todos << message
    rescue StandardError => e
      puts "\nError evaluating TodoOrDie calls"
      puts "Error: #{e.message}"
    ensure
      temp_file.unlink
    end

    # If we're in a CI environment and found overdue TODOs, fail the build
    if ENV['CI'] && overdue_todos.any?
      puts "\n❌ Found #{overdue_todos.length} overdue TODOs. Failing build."
      exit(1)
    elsif overdue_todos.any?
      puts "\n⚠️ Found #{overdue_todos.length} overdue TODOs."
    else
      puts "\n✅ No overdue TODOs found."
    end
  end

  private

  def find_todo_calls(node, file, content, todo_calls)
    return unless node.is_a?(Parser::AST::Node)

    # Look for TodoOrDie calls
    if node.type == :send && node.children[1] == :TodoOrDie
      # Get the line number
      line = node.loc.line

      # Extract the original code using the node's location
      code = content[node.loc.expression.begin_pos...node.loc.expression.end_pos]

      # Store the original code for evaluation
      todo_calls << {
        file: file,
        line: line,
        code: code,
        node: node,
      }
    end

    # Recursively check child nodes
    node.children.each do |child|
      find_todo_calls(child, file, content, todo_calls) if child.is_a?(Parser::AST::Node)
    end
  end
end
