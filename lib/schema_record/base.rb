require 'json'

module SchemaRecord
  class Base
    def initialize(**args)
      if additional_properties
        singleton_class.define_attributes(args.keys)
        args.each do |attr, value|
          set_value(attr, value)
        end
      else
        attributes.each do |attr|
          set_value(attr, args[attr.to_sym])
        end
      end
    end

    def self.json_schema_file(file_path)
      fullpath = File.join SchemaRecord.config.root_path, file_path
      schema_string = File.read(fullpath)
      schema = JSON.parse(schema_string)

      json_schema_hash(schema)
    end

    def self.json_schema_hash(schema)
      unless schema['type'] == 'object'
        raise InvalidSchemaError.new("top-level of json schema must be type: object")
      end

      @additional_properties = schema['additionalProperties'] != false

      properties = schema['properties']

      if properties.is_a?(Hash)
        define_attributes(properties.keys)
        properties.each do |attr, spec|
          if spec['type'] == 'object'
            nested_objects[attr] = Class.new(SchemaRecord::Base) do
              json_schema_hash spec
            end
          end
        end
      end
    end

    def self.define_attributes(attrs)
      @attributes = attrs
      self.send :attr_reader, *attrs
    end

    def self.attributes
      @attributes
    end

    def attributes
      self.class.attributes
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

    private
    def set_value(attr, value)
      if nested_objects[attr.to_s]
        value = nested_objects[attr.to_s].new value
      end

      self.instance_variable_set("@#{attr}", value)
    end
  end
end
