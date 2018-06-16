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
          case spec['type']
          when 'object'
            nested_objects[attr] = Class.new(SchemaRecord::Base) do
              json_schema_hash spec
            end
          when 'array'
            if spec['items']
              case spec['items']['type']
              when 'object'
                arrays_of_objects[attr] = Class.new(SchemaRecord::Base) do
                  json_schema_hash spec['items']
                end
              when 'array'
                # TODO: how to support array of ... array of objects???
              end
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

    def self.arrays_of_objects
      @arrays_of_objects ||= {}
    end

    def arrays_of_objects
      self.class.arrays_of_objects
    end

    private
    def set_value(attr, value)
      if nested_objects[attr.to_s]
        value = nested_objects[attr.to_s].new value
      elsif arrays_of_objects[attr.to_s]
        value.map! { |val| arrays_of_objects[attr.to_s].new val }
      end

      self.instance_variable_set("@#{attr}", value)
    end
  end
end
