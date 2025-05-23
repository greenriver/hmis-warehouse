namespace :test do
  desc 'Test generating an Exception'
  task :exception, [] => [:environment] do |_t, _args|
    raise StandardError.new('An Exception has been raised from within a Rake task.')
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
    require 'unparser'

    # Find all Ruby files in the application
    ruby_files = Dir.glob('{app,config,lib,drivers}/**/*.rb')

    puts "Found #{ruby_files.length} Ruby files to check"

    # Track all TodoOrDie calls
    todo_calls = []
    overdue_todos = []

    ruby_files.each do |file|
      # Parse the file
      ast = Parser::CurrentRuby.parse(File.read(file))

      # Find all TodoOrDie calls
      find_todo_calls(ast, file, todo_calls)
    rescue Parser::SyntaxError => e
      puts "Syntax error in #{file}: #{e.message}"
    rescue StandardError => e
      puts "Error processing #{file}: #{e.message}"
    end

    puts "\nFound #{todo_calls.length} TodoOrDie calls"

    # Evaluate each TodoOrDie call
    todo_calls.each do |call|
      # Create a new binding to evaluate the call
      binding = Object.new.instance_eval { binding }

      # Clean up the code by removing extra curly braces around hash arguments
      code = call[:code].gsub(/TodoOrDie\((.*?),\s*{([^}]+)}\)/, 'TodoOrDie(\1, \2)')

      begin
        # Evaluate the call
        result = eval(code, binding)

        # If the result is a TodoOrDie::OverdueTodo, it means the TODO is due
        if result.is_a?(TodoOrDie::OverdueTodo)
          message = "Overdue TODO found in #{call[:file]}:#{call[:line]}\nMessage: #{result.message}"
          puts "\n#{message}"
          overdue_todos << message
        end
      rescue TodoOrDie::OverdueTodo => e
        # Handle TodoOrDie errors specifically
        message = "Overdue TODO found in #{call[:file]}:#{call[:line]}\nMessage: #{e.message}"
        puts "\n#{message}"
        overdue_todos << message
      rescue StandardError => e
        puts "\nError evaluating TodoOrDie in #{call[:file]}:#{call[:line]}"
        puts "Error: #{e.message}"
      end
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

  def find_todo_calls(node, file, todo_calls)
    return unless node.is_a?(Parser::AST::Node)

    # Look for TodoOrDie calls
    if node.type == :send && node.children[1] == :TodoOrDie
      # Get the line number
      line = node.loc.line

      # Convert the node back to Ruby code
      code = Unparser.unparse(node)

      todo_calls << {
        file: file,
        line: line,
        code: code,
      }
    end

    # Recursively check child nodes
    node.children.each do |child|
      find_todo_calls(child, file, todo_calls) if child.is_a?(Parser::AST::Node)
    end
  end
end
