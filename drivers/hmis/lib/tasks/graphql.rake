require 'digest/sha1'

desc 'Update schema.graphql dump'
task dump_graphql_schema: [:environment, 'log:info_to_stdout'] do
  schema_definition = HmisSchema.to_definition
  schema_path = Rails.root.join('drivers', 'hmis', 'app', 'graphql', 'schema.graphql')

  old_sha = Digest::SHA1.hexdigest(File.read(schema_path))

  File.write(schema_path, schema_definition)

  new_sha = Digest::SHA1.hexdigest(File.read(schema_path))
  if old_sha != new_sha
    # Use 'abort' to exit with status code 1, to indicate that the schema has changed
    abort "Updated #{schema_path}"
  else
    puts 'Schema unchanged.'
  end
end
