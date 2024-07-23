require 'json'

namespace :ci do
  desc 'Analyze rspec profiles, write bucket assignments to file'
  task :build_bucket_assignments, [:profile_dir, :buckets_file, :max_minutes] => :environment do |_t, args|
    profile_dir = args[:profile_dir] || 'rspec_profiles'
    buckets_file = args.buckets_file || Rails.root.join('.github/rspec_buckets.json')
    max_minutes = (args[:max_minutes] || 20).to_i

    unless Dir.exist?(profile_dir)
      puts "Profile dir '#{profile_dir}' not found."
      exit 1
    end

    # Load and process profile data
    profile_groups = load_profile_data(profile_dir)

    # Filter out specs that run for less than 10 seconds
    filtered_specs = profile_groups.select { |group| group[:total_time] >= 10 }

    # Calculate total time and estimate number of buckets
    total_time = filtered_specs.sum { |spec| spec[:total_time] }
    estimated_buckets = (total_time / (max_minutes * 60.0)).ceil

    # Use bin packing algorithm to distribute specs
    buckets = bin_packing(filtered_specs, estimated_buckets)

    write_json_to_file(buckets, buckets_file)

    print_summary(buckets)
  end

  # WARNING: this modifies ruby source code to assign tags to specs.
  # After running this, you may need to update the matrix in rails_tests.yaml for new buckets
  # rails ci:update_spec_tags[/tmp/rspec_profiles/buckets.json]
  # profile information is generated from: rspec --format json --out rspec_results.json
  # or profile information cab be downloaded from gh actions archives
  desc 'Update RSpec test tags to match buckets file'
  task :update_spec_tags, [:buckets_file] => :environment do |_t, args|
    buckets_file = args.buckets_file || Rails.root.joins('.github/rspec_buckets.json')

    unless File.exist?(buckets_file)
      puts "Buckets file '#{buckets_file}' not found."
      exit 1
    end

    buckets = read_json_from_file(buckets_file)
    buckets.map!(&:deep_symbolize_keys)
    update_source_files(buckets)
  end

  def load_profile_data(profile_dir)
    profile_groups = []
    Dir.glob(File.join(profile_dir, '*.json')) do |file_path|
      profile_data = JSON.parse(File.read(file_path), symbolize_names: true)
      profile_groups += profile_data[:profile][:groups]
    end
    profile_groups
  end

  def read_json_from_file(file_path)
    json_data = File.read(file_path)
    JSON.parse(json_data)
  end

  def write_json_to_file(json, file_path)
    File.open(file_path, 'w') do |file|
      file.write(JSON.pretty_generate(json))
    end
  end

  def bin_packing(specs, num_buckets)
    buckets = Array.new(num_buckets) { { id: nil, total_time: 0, specs: [] } }

    # Sort specs by total_time in descending order
    sorted_specs = specs.sort_by { |spec| -spec[:total_time] }

    sorted_specs.each do |spec|
      # Find the bucket with the least total time
      target_bucket = buckets.min_by { |bucket| bucket[:total_time] }

      # Add the spec to the target bucket
      target_bucket[:total_time] += spec[:total_time]
      target_bucket[:specs] << spec
    end

    # Assign IDs to non-empty buckets
    buckets.reject! { |bucket| bucket[:specs].empty? }
    buckets.each_with_index { |bucket, index| bucket[:id] = "bucket-#{index + 1}" }

    buckets
  end

  def update_source_files(buckets)
    buckets.each do |bucket|
      bucket[:specs].each do |spec|
        file_path, = spec[:location].split(':')
        content = File.readlines(file_path)

        describe_line_index = content.index { |line| line.strip.start_with?('RSpec.describe') }

        if describe_line_index
          describe_line = content[describe_line_index]

          updated_line = if describe_line.include?('ci_bucket:')
            describe_line.gsub(/ci_bucket:\s*['"][\w\d-]+['"]/, "ci_bucket: '#{bucket[:id]}'")
          else
            parts = describe_line.rstrip.split(/\s*do\s*$/)
            "#{parts[0]}, ci_bucket: '#{bucket[:id]}' do#{parts[1]}\n"
          end

          content[describe_line_index] = updated_line
          File.write(file_path, content.join)
          puts "Updated #{file_path} with ci_bucket: '#{bucket[:id]}'"
        else
          puts "Could not find RSpec.describe line in #{file_path}"
        end
      end
    end
  end

  def print_summary(buckets)
    puts "Processed #{buckets.sum { |b| b[:specs].size }} test files across #{buckets.size} buckets."
    buckets.each do |bucket|
      puts "#{bucket[:id]}: #{bucket[:specs].size} specs, total time: #{(bucket[:total_time].round / 60).round} minutes"
    end
  end
end
