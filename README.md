
[![Build
Status](https://api.travis-ci.org/repositories/freshtonic/lazylet.svg?branch=master)](https://travis-ci.org/freshtonic/lazylet.git)

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

  var LazyLet = require('lazylet'), env = LazyLet.Env(), Let = env.Let;

  describe("lazylet usage", function() {

    it("can define a variable", function() {
      Let('name', 'James Sadler');
      expect(env.name).toEqual("James Sadler");
    });

    it("can define a variable that is depends on another and is computed on demand", function() {
      Let('name', 'James Sadler');
      Let('message', function() {
        return "Hello, " + this.name + "!";
      });
      expect(env.message).toEqual('Hello, James Sadler!');
    });

    it('can define variables in bulk', function() {
      Let({
        name: 'James Sadler',
        age: 36
      });
      expect(env.name).toEqual('James Sadler');
      expect(env.age).toEqual(36);
    });

    it("does not clear the environment when declaring variables individually", function() {
      Let('name', 'James Sadler');
      Let('age', 36);
      expect(env.name).toEqual("James Sadler");
      expect(env.age).toEqual(36);
    });

    it('provides a way to explicitly clear the environment', function() {
      Let('name', 'James Sadler');
      Let.clear();
      expect(typeof env.name).toBe('undefined');
    });

    it('can define variable in terms of the existing value', function() {
      Let('array', [1, 2, 3]);
      Let('array', function() {
        return this.array.concat(4);
      });
      expect(env.array).toEqual([1, 2, 3, 4]);
    });

    it('memoizes variables when they are evaluated', function() {
      var count;
      count = 0;
      Let({
        name: function() {
          count += 1;
          return 'James';
        }
      });
      env.name;
      expect(count).toEqual(1);
      env.name;
      expect(count).toEqual(1);
    });

    it('forgets the memoization for all variables when any variable is redefined', function() {
      var count;
      count = 0;
      Let({
        name: function() {
          count += 1;
          return 'James';
        }
      });
      expect(env.name).toEqual('James');
      expect(count).toEqual(1);
      Let({
        age: function() {
          return 36;
        }
      });
      expect(env.name).toEqual('James');
      expect(count).toEqual(2);
    });

    it('uses memoized variables when variables are defined in terms of others', function() {
      var count;
      count = 0;
      Let({
        val1: function() {
          count += 1;
          return count;
        },
        val2: function() {
          return this.val1;
        }
      });
      expect(env.val1).toEqual(1);
      expect(env.val2).toEqual(1);
    });

    describe('behaving in sane manner', function() {
      it('does not allow redefinition of "Let"', function() {
        expect(function() {
          Let('Let', 'anything');
        }).toThrow('cannot redefine Let');
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

