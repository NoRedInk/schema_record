# SchemaRecord

Are you tired of receiving json from the front-end and having to access it as a hash? Do you wish you could access that data using Ruby objects, accessor methods, and receive a NoMethodError when trying to access an attribute that doesn't exist? Well, then SchemaRecord is the gem for you!


## Usage

Let's say you've invented the newest social media craze, Twinter: twitter for winter lovers. When a user submits a new post, it has the following schema:

```json
// post-schema.json
{
    "description": "A Twinter post",
    "type": "object",
    "additionalProperties": false,
    "properties": {
        "content": { "type": "string" },
        "userId": { "type": "integer" },
        "metadata": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
                "localTemp": { "type": "number" },
                "snowFall": { "type": "number" }
            }
        }
    }
}
```

If we create a new SchemaRecord model, we can access any json that fits this schema using ruby objects.

```ruby
class TwinterPost < SchemaRecord::Base
    json_schema_file "path/to/post-schema.json"
end

post_data = {
    "content" => "Hello world.",
    "userId" => 1,
    "metadata" => {
        "localTemp" => 4,
        "snowFall" => 3.2
    }
}

post = TwinterPost.new post_data

post.content            # ==> "Hello world."
post.userId             # ==> 1
post.metadata.localTemp # ==> 4
post.metadata.snowFall  # ==> 3.2
post.notInSchema # ==> raises a NoMethodError
post.metadata # ==> a record that inherits from SchemaRecord::Base
```

### Beware of forgetting to set "additionalProperties" to false

SchemaRecord respects json schemas definition of `additionalProperties`. That means, if you don't set it at all, it will allow your record to be initialized with any attribute name. For example, this schema does not set additionalProperties to `false`.

```json
// person-schema.json
{
    "description": "A person",
    "type": "object",
    "properties": {
        "name": { "type": "string" },
        "userId": { "type": "integer" }
    }
}
```

A record defined using this schema can be initialized with any attributes:

```ruby
class Person < SchemaRecord::Base
    json_schema_file "path/to/person-schema.json"
end

data = {
    "name" => "Katherine Johnson",
    "userId" => 1,
    "employer" => "NASA",
    "birthdate" => "August 26, 1918"
}

kat = TwinterPost.new data

# attributes defined in the schema
kat.name      # ==> "Katherine Johnson"
kat.userId    # ==> 1

# attributes not in the schema, but in the `data`
kat.employer  # ==> "NASA"
kat.birthdate # ==> "August 26, 1918"

# attribute neither in the schema nor `data`
kat.notInData # ==> raises NoMethodError
```

### This is not a schema validator

Defining and initializing a SchemaRecord instance *does not* validate that the data you are passing in fits the specified schema. If the data *does* align with the schema, the resulting SchemaRecord will behave as expected. If the data being used to initialize a SchemaRecord model does *not* align with the specified schema, **the resulting behavior is undefined!**

## Not Yet Supported
- $ref
- patternProperties
- oneOf


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schema_record'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install schema_record

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/schema_record. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SchemaRecord project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/schema_record/blob/master/CODE_OF_CONDUCT.md).
