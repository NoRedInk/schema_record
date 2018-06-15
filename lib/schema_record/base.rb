require 'json'

module SchemaRecord
  class Base
    @additional_properties = true

    def initialize(**args)
      if additional_properties
        singleton_class.define_attributes(args.keys)
        args.each do |attr, value|
          self.instance_variable_set("@#{attr}", value)
        end
      else
        attributes.each do |attr|
          self.instance_variable_set("@#{attr}", args[attr.to_sym])
        end
      end
    end

    def self.json_schema(file_path)
      fullpath = File.join SchemaRecord.config.root_path, file_path
      schema_string = File.read(fullpath)
      schema = JSON.parse(schema_string)

      unless schema['type'] == 'object'
        raise InvalidSchemaError.new("top-level of json schema must be type: object")
      end

      properties = schema['properties']
      unless properties.is_a?(Hash)
        raise InvalidSchemaError.new("type is 'object', but 'properties' hash is missing")
      end

      define_attributes(properties.keys)
      @additional_properties = schema['additionalProperties'] != false
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
  end
end
