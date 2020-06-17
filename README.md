# danger-detect_unused_definition

A description of danger-detect_unused_definition.

## Installation

    $ gem install danger-detect_unused_definition

## Usage

Methods and attributes from this plugin are available in
your `Dangerfile` under the `detect_unused_definition` namespace.
    
```
detect_unused_definition.allow_paths = ["SampleApp", "SampleAppTests"]
detect_unused_definition.deny_paths = ["Model/*"]
detect_unused_definition.detect
```

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
