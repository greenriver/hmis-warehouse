require 'digest/sha1'

desc 'Update schema.graphql dump'
task dump_graphql_schema: [:environment, 'log:info_to_stdout'] do
  schema_definition = HmisSchema.to_definition
  schema_path = Rails.root.join('drivers', 'hmis', 'app', 'graphql', 'schema.graphql')

  old_sha = Digest::SHA1.hexdigest(File.read(schema_path))

  File.write(schema_path, schema_definition)

  new_sha = Digest::SHA1.hexdigest(File.read(schema_path))
  if old_sha != new_sha
    puts "Updated #{schema_path}"
    # Needed for GitHub Actions check:
    # Exit with status code 1 to indicate that the schema has changed
    exec('false')
  else
    puts 'Schema unchanged.'
  end
end
