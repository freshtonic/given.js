
[![Build
Status](https://travis-ci.org/freshtonic/lazylet.svg?token=f5a853d113c43cdedc317d637e9b22e7daedce01&branch=master)](https://travis-ci.org/freshtonic/lazylet.git)

# lazylet

*lazylet* is a lazy-evaluation system for use in your specs.

Variables are defined within an environment object and are lazily computed on
demand. A variable can hold either a value, function or object. If the variable
is a function it used for computing the value of the variable when it is
accessed from the environment.

Variables are accessed from the environment as if they are plain JS properties.
Under the hood, the properties are defined using Object.defineProperty with
a 'get' accessor in order that their value can be computed on demand.

## Installation

Add it to your package.json or `npm install lazylet`.

## Usage

```javascript

  var env = require('lazylet');

  describe("lazylet usage", function() {

    it("can define a variable", function() {
      env.Let('name', 'James Sadler');
      expect(env.name).toEqual("James Sadler");
    });

    it("can define a variable that is depends on another and is computed on demand", function() {
      env.Let('name', 'James Sadler');
      env.Let('message', function() {
        return "Hello, " + this.name + "!";
      });
      expect(env.message).toEqual('Hello, James Sadler!');
    });

    it("does not clear the environment when declaring variables individually", function() {
      env.Let('name', 'James Sadler');
      env.Let('age', 36);
      expect(env.name).toEqual("James Sadler");
      expect(env.age).toEqual(36);
    });

    it("clears the environment when declaring variables in bulk", function() {
      env.Let('name', 'James Sadler');
      env.Let('age', 36);
      env.Let({
        name: 'James Sadler'
      });
      expect(typeof env.age).toBe('undefined');
    });

    it('permits bulk declaration of variables without clearing the environment', function() {
      env.Let('name', 'James Sadler');
      env.Let('age', 36);
      env.Let.preserve({
        name: 'James Sadler'
      });
      expect(env.age).toBe(36);
    });

    it('provides a way to explicitly clear the environment', function() {
      env.Let('name', 'James Sadler');
      env.Let.clear();
      expect(typeof env.name).toBe('undefined');
    });

    describe('behaving in sane manner', function() {

      it('does not allow redefinition of "Let"', function() {
        expect(function() {
          return env.Let('Let', 'anything');
        }).toThrow('cannot redefine Let');
      });

      it('does not allow Let to be directly overwritten', function() {
        env.Let = 'something else';
        expect(typeof env.Let).toEqual('function');
      });
    });
  });

```

## Caveats

To set a variable with a value that *is* a function, nest it within
another function (to avoid ambiguity with dynamically computing a value), like so:

```javascript

env.Let('aFunction', function() {
    // This function will be the variable's value.
    return function() {
        return 'foo';
    };
});

```

## Running the specs

Run `make spec`.

Install the `wach` node module if you would like to have the specs run
automatically when the source or specs are modified.

- `npm install -g wach`
- `make watch`

## Contributing

1. Fork it ( https://github.com/freshtonic/lazylet/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Licence

Copyright (c) 2014, lazylet is developed and maintained by James Sadler, and is
released under the open MIT Licence.

