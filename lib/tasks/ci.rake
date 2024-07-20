require 'json'

namespace :ci do
  # rails ci:update_spec_tags[/tmp/rspec_profiles]
  desc 'Update RSpec test tags based on profiling data'
  task :update_spec_tags, [:profile_dir] => :environment do |_t, args|
    profile_dir = args[:profile_dir] || 'rspec_profiles'

    unless Dir.exist?(profile_dir)
      puts "Profile dir '#{profile_dir}' not found."
      exit 1
    end

    profile_groups = []
    Dir.foreach(profile_dir) do |filename|
      next unless filename.end_with?('.json')

      file_path = File.join(profile_dir, filename)
      File.open(file_path, 'r') do |file|
        profile_data = JSON.parse(File.read(file), symbolize_names: true)
        profile_groups += profile_data[:profile][:groups]
      end
    end

    # Initialize buckets
    buckets = []
    current_bucket = { id: 'bucket-1', total_time: 0, specs: [] }
    bucket_index = 1

    # get a better distribution
    rng = Random.new(3)
    profile_groups = profile_groups.shuffle(random: rng)

    # Categorize specs into buckets
    profile_groups.each do |group|
      total_time = group[:total_time]

      # Skip specs that run for less than 10 seconds
      next if total_time < 10

      if current_bucket[:total_time] + total_time > (60 * 40)
        buckets << current_bucket
        bucket_index += 1
        current_bucket = { id: "bucket-#{bucket_index}", total_time: 0, specs: [] }
      end

      current_bucket[:total_time] += total_time
      current_bucket[:specs] << { location: group[:location], total_time: total_time }
    end

    # Add the last bucket if it's not empty
    buckets << current_bucket if current_bucket[:specs].any?

    # Update the source files
    buckets.each do |bucket|
      bucket[:specs].each do |spec|
        file_path, = spec[:location].split(':')

        # Read the file content
        content = File.readlines(file_path)

        # Find the first RSpec.describe line
        describe_line_index = content.index { |line| line.strip.start_with?('RSpec.describe') }

        if describe_line_index
          describe_line = content[describe_line_index]

          if describe_line.include?('ci_bucket:')
            # Update existing ci_bucket
            updated_line = describe_line.gsub(/ci_bucket:\s*['"][\w\d-]+['"]/, "ci_bucket: '#{bucket[:id]}'")
          else
            # Add ci_bucket before the 'do'
            parts = describe_line.rstrip.split(/\s*do\s*$/)
            updated_line = "#{parts[0]}, ci_bucket: '#{bucket[:id]}' do#{parts[1]}\n"
          end

          content[describe_line_index] = updated_line

          # Write the updated content back to the file
          File.write(file_path, content.join)
          puts "Updated #{file_path} with ci_bucket: '#{bucket[:id]}'"
        else
          puts "Could not find RSpec.describe line in #{file_path}"
        end
      end
    end

    puts "Processed #{buckets.sum { |b| b[:specs].size }} test files across #{buckets.size} buckets."
    buckets.each do |bucket|
      puts "#{bucket[:id]}: #{bucket[:specs].size} specs, total time: #{(bucket[:total_time].round / 60).round} minutes"
    end
  end
end
