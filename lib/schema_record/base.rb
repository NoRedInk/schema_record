require 'json'

module SchemaRecord
  class Base
    def initialize(**args)
      if additional_properties
        singleton_class.define_properties(args.keys)
        args.each do |prop, value|
          set_value(prop, value)
        end
      else
        properties.each do |prop|
          set_value(prop, args[prop.to_sym])
        end
      end
    end

    def self.json_schema_file(file_path)
      fullpath = File.join SchemaRecord.config.root_path, file_path
      schema_string = File.read(fullpath)
      schema = JSON.parse(schema_string)

      unless Array(schema['type']).include? 'object'
        raise InvalidSchemaError.new("top-level of json schema must be type: object")
      end

      json_schema_hash(schema)
    end

    def self.json_schema_hash(schema)
      @additional_properties = schema['additionalProperties'] != false

      properties = schema['properties']

      if properties.is_a?(Hash)
        define_properties(properties.keys)
        properties.each do |prop, spec|
          Array(spec['type']).each do |type|
            case type
            when 'object'
              nested_objects[prop] = Class.new(SchemaRecord::Base) do
                json_schema_hash spec
              end
            when 'array'
              array_schemas[prop] = Class.new(SchemaRecord::List) do
                json_schema_hash spec['items']
              end
            end
          end
        end
      end
    end

    def self.define_properties(props)
      @properties = props
      self.send :attr_reader, *props
    end

    def self.properties
      @properties
    end

    def properties
      self.class.properties
    end

    def self.additional_properties
      @additional_properties
    end

    def additional_properties
      self.class.additional_properties
    end

    def self.nested_objects
      @nested_objects ||= {}
    end

    def nested_objects
      self.class.nested_objects
    end

    def self.array_schemas
      @array_schemas ||= {}
    end

    def array_schemas
      self.class.array_schemas
    end

    private
    def set_value(prop, arg)
      value =
        if arg.is_a?(Hash) && nested_objects[prop.to_s]
          nested_objects[prop.to_s].new arg
        elsif arg.is_a?(Array) && array_schemas[prop.to_s]
          arg.map { |item| array_schemas[prop.to_s].initialize_item item }
        else
          arg
        end

      self.instance_variable_set("@#{prop}", value)
    end
  end
end
