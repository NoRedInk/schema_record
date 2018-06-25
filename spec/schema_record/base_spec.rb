require 'spec_helper'

RSpec.describe SchemaRecord::Base do
  before do
    SchemaRecord.config do |config|
      config.root_path = File.expand_path '../..', __FILE__
    end
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

  context "with patternProperties" do
    it "can be initialized only with defined properties" do
      cast_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/cast.json'
      end

      cast = cast_record.new(
        "wolverine": "Hugh Jackman",
        "professor": "Patrick Stewart",
        "others": 11,
        "noMatch": 'should fail'
      )

      expect(cast.wolverine).to eq "Hugh Jackman"
      expect(cast.professor).to eq "Patrick Stewart"
      expect(cast.others).to eq 11
      expect { cast.noMatch }.to raise_error(NoMethodError)
    end

    it "supports nested objects and arrays" do
      cast_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/complex_cast.json'
      end

      cast = cast_record.new(
        "wolverine": {
          "firstName": "Hugh",
          "lastName": "Jackman"
        },
        "professor": {
          "firstName": "Patrick",
          "lastName": "Stewart"
        },
        "others": 11,
        "_updates": ["2018-06-17", "2018-06-18"],
        "noMatch": 'should fail'
      )

      expect(cast.wolverine.firstName).to eq "Hugh"
      expect(cast.wolverine.lastName).to eq "Jackman"
      expect(cast.professor.firstName).to eq "Patrick"
      expect(cast.professor.lastName).to eq "Stewart"
      expect(cast._updates).to eq ["2018-06-17", "2018-06-18"]
      expect(cast.others).to eq 11
      expect { cast.noMatch }.to raise_error(NoMethodError)
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
    it "can be initialized (and read) given nested data" do
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

  context "when the schema specifies an array" do
    it "can be initialized (and read) given json objects in an array" do
      computer_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/computer.json'
      end

      computer = computer_record.new(
        cpu: "intel",
        ram: 16,
        drives: [
          { capacity: "2T", rpm: 7200 },
          { capacity: "2T", rpm: 15000 },
        ]
      )

      expect(computer.cpu).to eq "intel"
      expect(computer.ram).to eq 16
      expect(computer.drives.first).to have_attributes(capacity: "2T", rpm: 7200)
      expect(computer.drives.last).to have_attributes(capacity: "2T", rpm: 15000)
    end

    it "can be initialized (and read) given json objects in an array of arrays" do
      gameboard_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/gameboard.json'
      end

      gameboard = gameboard_record.new(
        game: 'zuxzoog',
        board: [
          [
            { piece: 'triangle', player: 1 },
            { piece: 'square', player: 2 }
          ],
          [
            { piece: 'triangle', player: 2 },
            { piece: 'hexagon', player: 1 }
          ]
        ]
      )

      expect(gameboard.game).to eq 'zuxzoog'
      expect(gameboard.board[0][0]).to have_attributes(
        piece: 'triangle', player: 1
      )
      expect(gameboard.board[0][1]).to have_attributes(
        piece: 'square', player: 2
      )
      expect(gameboard.board[1][0]).to have_attributes(
        piece: 'triangle', player: 2
      )
      expect(gameboard.board[1][1]).to have_attributes(
        piece: 'hexagon', player: 1
      )
    end
  end

  context "multiple types" do
    it "can assign an attribute as an object or null" do
      person_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/complex_person_with_nulls.json'
      end

      ironman = person_record.new(
        firstName: 'Iron',
        lastName: 'Man',
        appearance: {
          height: 80,
          weight: 4000
        }
      )

      curie = person_record.new(
        firstName: "Marie",
        lastName: "Curie",
        appearance: nil
      )

      expect(ironman.firstName).to eq 'Iron'
      expect(ironman.lastName).to eq 'Man'
      expect(ironman.appearance.height).to eq 80
      expect(ironman.appearance.weight).to eq 4000

      expect(curie.firstName).to eq 'Marie'
      expect(curie.lastName).to eq 'Curie'
      expect(curie.appearance).to be_nil
    end

    it "can assign an attribute as a list or null" do
      computer_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/computer_with_nulls.json'
      end

      computer = computer_record.new(
        cpu: "intel",
        ram: 16,
        drives: [
          { capacity: "2T", rpm: 7200 },
          { capacity: "2T", rpm: 15000 },
        ]
      )

      parts = computer_record.new(
        cpu: "amd",
        ram: 8,
        drives: nil
      )

      expect(computer.cpu).to eq "intel"
      expect(computer.ram).to eq 16
      expect(computer.drives.first).to have_attributes(capacity: "2T", rpm: 7200)
      expect(computer.drives.last).to have_attributes(capacity: "2T", rpm: 15000)

      expect(parts.cpu).to eq 'amd'
      expect(parts.ram).to eq 8
      expect(parts.drives).to eq nil
    end

    it "can assign a list of objects, lists, or nulls" do
      jabberwocky_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/jabberwocky.json'
      end

      jabberwocky = jabberwocky_record.new(
        wabe: [
          ["gyre", "gimble"],
          nil,
          {
            jaws: "bite",
            claws: "catch"
          }
        ]
      )

      expect(jabberwocky.wabe[0]).to eq ["gyre", "gimble"]

      expect(jabberwocky.wabe[1]).to be_nil

      expect(jabberwocky.wabe[2].jaws).to eq 'bite'
      expect(jabberwocky.wabe[2].claws).to eq 'catch'
    end
  end

  context "$ref" do
    context "when $ref refers to a part of the same file" do
      it "works " do
        customer_record = Class.new(SchemaRecord::Base) do
          json_schema_file 'schemas/customer.json'
        end

        customer = customer_record.new(
          shipping_address: {
            city: "New York",
            state: "NY"
          },
          billing_address: {
            city: "San Francisco",
            state: "CA"
          }
        )

        expect(customer.shipping_address.city).to eq "New York"
        expect(customer.shipping_address.state).to eq "NY"
        expect(customer.billing_address.city).to eq "San Francisco"
        expect(customer.billing_address.state).to eq "CA"
      end

      it "raises an exception when the path doesn't exist" do
        expect {
          Class.new(SchemaRecord::Base) do
            json_schema_file 'schemas/broken_ref.json'
          end
        }.to raise_error(ArgumentError)
      end
    end

    context "when $ref refers to a different file" do
      it "works when referring to the whole file" do
        family_record = Class.new(SchemaRecord::Base) do
          json_schema_file 'schemas/family.json'
        end

        family = family_record.new(
          guardians: [
            {firstName: 'Bob', lastName: 'Belcher'},
            {firstName: 'Linda', lastName: 'Belcher'}
          ],
          children: [
            {firstName: 'Tina', lastName: 'Belcher'},
            {firstName: 'Jean', lastName: 'Belcher'},
            {firstName: 'Louise', lastName: 'Belcher'}
          ]
        )

        expect(family.guardians[0].firstName).to eq 'Bob'
        expect(family.guardians[1].firstName).to eq 'Linda'
        expect(family.children[0].firstName).to eq 'Tina'
        expect(family.children[1].firstName).to eq 'Jean'
        expect(family.children[2].firstName).to eq 'Louise'
        expect(family.guardians.map(&:lastName).uniq).to eq ['Belcher']
        expect(family.children.map(&:lastName).uniq).to eq ['Belcher']
      end

      it "works when referring to a part of the other file" do
        location_record = Class.new(SchemaRecord::Base) do
          json_schema_file 'schemas/location.json'
        end

        location = location_record.new(
          name: 'NoRedInk',
          address: {city: 'San Francisco', state: 'CA'}
        )

        expect(location.name).to eq 'NoRedInk'
        expect(location.address.city).to eq 'San Francisco'
        expect(location.address.state).to eq 'CA'
      end

      context "and that has $refs as well" do
        it "works" do
          sale_record = Class.new(SchemaRecord::Base) do
            json_schema_file 'schemas/sale.json'
          end

          sale = sale_record.new(
            buyer: {
              shipping_address: {
                city: "New York",
                state: "NY"
              },
              billing_address: {
                city: "San Francisco",
                state: "CA"
              }
            },
            seller: {
              firstName: "Agatha",
              lastName: "Christie"
            },
            location: {
              name: 'NoRedInk',
              address: {city: 'San Francisco', state: 'CA'}
            }
          )

          expect(sale.buyer.shipping_address.city).to eq "New York"
          expect(sale.buyer.shipping_address.state).to eq "NY"
          expect(sale.buyer.billing_address.city).to eq "San Francisco"
          expect(sale.buyer.billing_address.state).to eq "CA"
          expect(sale.seller.firstName).to eq 'Agatha'
          expect(sale.seller.lastName).to eq 'Christie'
          expect(sale.location.name).to eq 'NoRedInk'
          expect(sale.location.address.city).to eq 'San Francisco'
          expect(sale.location.address.state).to eq 'CA'
        end
      end
    end

    it "works when the $ref path has escaped characters" do
      escaped_ref_record = Class.new(SchemaRecord::Base) do
        json_schema_file 'schemas/escaped_ref.json'
      end

      escaped = escaped_ref_record.new(
        color: {
          red: 10,
          green: 80,
          blue: 200
        }
      )

      expect(escaped.color.red).to eq 10
      expect(escaped.color.green).to eq 80
      expect(escaped.color.blue).to eq 200
    end
  end
end
