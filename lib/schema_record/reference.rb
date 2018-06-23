require 'json'

module SchemaRecord
  module Reference
    module_function
    def fetch_schema(path, root_schema)
      filename, *properties = path.split('/')
      case filename
      when '#'
        fetch_local_schema(properties, root_schema)
      else
        nil # fetch_schema_from_file(filename, context)
      end
    end

    private_class_method
    def fetch_local_schema(properties, root_schema)
      properties.reduce(root_schema) do |schema, prop|
        if schema && schema.has_key?(prop)
          schema[prop]
        else
          raise InvalidArgument.new("Unable to find schema at $ref path <#{path}>")
        end
      end
    end

    def fetch_schema_from_file(filename, context)
      filepath = File.join context.directory, filename
      new_context = Context.new(filepath)

    end
  end
end
