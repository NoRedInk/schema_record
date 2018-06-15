require 'spec_helper'

RSpec.describe SchemaRecord::Base do
  before do
    SchemaRecord.config do |config|
      config.root_path = File.expand_path '../..', __FILE__
    end
  end

  it "fails on definition if the schema isn't type: object" do
    expect {
      Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/invalid_not_object.json'
      end
    }.to raise_error(SchemaRecord::InvalidSchemaError)
  end

  it "can define a record with attributes that match the schema" do
    location_record = Class.new(SchemaRecord::Base) do
      json_schema_file 'schemas/geo_location.json'
    end

    location = location_record.new(latitude: 10, longitude: 20)
    expect(location.latitude).to eq 10
    expect(location.longitude).to eq 20
  end

  context "additionalProperties: false" do
    it "only defined properties will store a value or have a getter method" do
      person_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/person.json'
      end

      person = person_record.new firstName: 'Iron', lastName: 'Man', age: 42
      expect(person.firstName).to eq 'Iron'
      expect(person.lastName).to eq 'Man'
      expect { person.age }.to raise_error(NoMethodError)
    end
  end

  context "additionalProperties: anything-other-than-false" do
    it "additional properties passed into initialize will be stored and have getters" do
      location_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/geo_location.json'
      end

      location = location_record.new(latitude: 10, longitude: 20, name: 'home')
      expect(location.latitude).to eq 10
      expect(location.longitude).to eq 20
      expect(location.name).to eq 'home'
    end

    it "different instances can have different properties" do
      location_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/geo_location.json'
      end

      home = location_record.new(latitude: 10, longitude: 20, name: 'home')
      work = location_record.new(latitude: 11, longitude: 21)
      park = location_record.new(latitude: 12, longitude: 22, dogs: 'allowed')

      expect(home.name).to eq 'home'
      expect { work.name }.to raise_error(NoMethodError)
      expect { park.name }.to raise_error(NoMethodError)

      expect(park.dogs).to eq 'allowed'
      expect { home.dogs }.to raise_error(NoMethodError)
      expect { work.dogs }.to raise_error(NoMethodError)
    end
  end

  it "different records with different additionalProperties can co-exist" do
    location_record = Class.new(SchemaRecord::Base) do
      json_schema_file 'schemas/geo_location.json'
    end

    person_record = Class.new(SchemaRecord::Base) do
      json_schema_file 'schemas/person.json'
    end

    location = location_record.new(latitude: 10, longitude: 20, name: 'home')
    expect(location.latitude).to eq 10
    expect(location.longitude).to eq 20
    expect(location.name).to eq 'home'

    person = person_record.new firstName: 'Iron', lastName: 'Man', age: 42
    expect(person.firstName).to eq 'Iron'
    expect(person.lastName).to eq 'Man'
    expect { person.age }.to raise_error(NoMethodError)
  end

  context "with a property of {type: object} (i.e. nesting)" do
    it "can be initialized and read from using nested data" do
      person_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/complex_person.json'
      end

      person = person_record.new(
        firstName: 'Iron',
        lastName: 'Man',
        appearance: {
          height: 80,
          weight: 4000,
          unexpected: 'property'
        }
      )

      expect(person.firstName).to eq 'Iron'
      expect(person.lastName).to eq 'Man'
      expect(person.appearance.height).to eq 80
      expect(person.appearance.weight).to eq 4000
      expect { person.appearance.unexpected }.to raise_error(NoMethodError)
    end
  end
end
