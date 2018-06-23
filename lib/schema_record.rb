require "schema_record/version"
require "schema_record/base"
require "schema_record/list"
require "schema_record/reference"
require "schema_record/config"
require "schema_record/invalid_schema_error"

module SchemaRecord
  def self.config
    if block_given?
      yield the_config
    else
      the_config
    end
  end

  private_class_method
  def self.the_config
    @the_config ||= Config.new
  end
end
