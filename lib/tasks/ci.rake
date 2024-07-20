
require 'json'

namespace :ci do
  desc "Update RSpec test tags based on profiling data"
  task :update_spec_tags, [:profile_file] => :environment do |t, args|
    profile_file = args[:profile_file] || 'rspec_profile.json'

    unless File.exist?(profile_file)
      puts "Profile file '#{profile_file}' not found."
      exit 1
    end

    # Read and parse the profile JSON file
    profile_data = JSON.parse(File.read(profile_file), symbolize_names: true)

    # Define the buckets
    buckets = [
      { id: 'large', bounds: (500..) },
      { id: 'medium', bounds: (10...500) }
    ]

    # Process and categorize the test files
    categorized_tests = profile_data[:profile][:groups].map do |group|
      total_time = group[:total_time]
      location = group[:location]

      bucket = buckets.find { |b| b[:bounds].cover?(total_time) }
      next unless bucket

      { location: location, bucket: bucket[:id] }
    end.compact

    # Update the source files
    categorized_tests.each do |test|
      file_path, line_number = test[:location].split(':')
      bucket = test[:bucket]

      # Read the file content
      content = File.readlines(file_path)

      # Find the first RSpec.describe line
      describe_line_index = content.index { |line| line.strip.start_with?('RSpec.describe') }

      if describe_line_index
        describe_line = content[describe_line_index]

        if describe_line.include?('ci_bucket:')
          # Update existing ci_bucket
          updated_line = describe_line.gsub(/ci_bucket:\s*['"][\w\d]+['"]/, "ci_bucket: '#{bucket}'")
        else
          # Add ci_bucket before the 'do'
          parts = describe_line.rstrip.split(/\s*do\s*$/)
          updated_line = "#{parts[0]}, ci_bucket: '#{bucket}' do#{parts[1]}\n"
        end

        content[describe_line_index] = updated_line

        # Write the updated content back to the file
        File.write(file_path, content.join)
        puts "Updated #{file_path} with ci_bucket: '#{bucket}'"
      else
        puts "Could not find RSpec.describe line in #{file_path}"
      end
    end

    puts "Processed #{categorized_tests.size} test files."
  end
end
