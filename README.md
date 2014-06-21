
[![Build
Status](https://api.travis-ci.org/repositories/freshtonic/given.svg?branch=master)](https://travis-ci.org/freshtonic/given.git)

# Given

*Given* is a lazy-evaluation system for use in your specs.

Variables are defined within an environment object and are lazily computed on
demand. A variable can hold either a value, function or object. If the variable
is a function it used for computing the value of the variable when it is
accessed from the environment.

Variables are accessed from the environment as if they are plain JS properties.
Under the hood, the properties are defined using Object.defineProperty with
a 'get' accessor in order that their value can be computed on demand.

_WARNING_: Given is not yet stable. The API may change significantly before
1.0.0 and there may be show-stopping bugs.

## Installation

Add it to your package.json or `npm install given`.

## Usage

### Javascript

```js

  Given = require('../build/given');

  expect = require('expect.js');

  describe("Given", function() {
    var env, given;
    given = env = undefined;
    beforeEach(function() {
      env = Given.Env();
      return given = env.given;
    });

    it("can define a variable", function() {
      given('name', 'James Sadler');
      expect(env.name).to.equal("James Sadler");
    });

    it("can define a variable that is depends on another and is computed on demand", function() {
      given('name', 'James Sadler');
      given('message', function() {
        return "Hello, " + this.name + "!";
      });

      expect(env.message).to.equal('Hello, James Sadler!');
    });

    it('can define variables in bulk', function() {
      given({
        name: 'James Sadler',
        age: 36
      });

      expect(env.name).to.equal('James Sadler');
      expect(env.age).to.equal(36);
    });

    it('provides a way to explicitly clear the environment', function() {
      given('name', 'James Sadler');
      given.clear();
      expect(typeof env.name).to.be('undefined');
    });

    it('can define variable in terms of the existing value', function() {
      given('array', function() {
        return [1];
      });

      given('array', function() {
        return this.array.concat(2);
      });

      given('array', function() {
        return this.array.concat(3);
      });

      expect(env.array).to.eql([1, 2, 3]);
    });

    it('supports the definition of variables that depend on a variable that is not yet defined', function() {
      given({
        foo: function() {
          return this.bar;
        }
      });

      given({
        bar: function() {
          return 'Bar';
        }
      });

      expect(env.foo).to.equal('Bar');
    });

    it('supports the redefinition of', function() {
      given({
        name1: function() {
          return "James";
        }
      });

      given({
        message: function() {
          return "" + this.name1 + " and " + this.name2;
        }
      });

      given({
        name2: function() {
          return "Kellie";
        }
      });

      expect(env.message).to.equal('James and Kellie');
    });

    it('memoizes variables when they are evaluated', function() {
      var count;
      count = 0;
      given({
        name: function() {
          count += 1;
          return 'James';
        }
      });

      env.name;
      expect(count).to.equal(1);
      env.name;
      expect(count).to.equal(1);
    });

    it('uses memoized variables when variables are defined in terms of others', function() {
      var count;
      count = 0;
      given({
        val1: function() {
          count += 1;
          return count;
        }
      });

      given({
        val2: function() {
          return this.val1;
        }
      });

      expect(env.val1).to.equal(1);
      expect(env.val2).to.equal(1);
    });

    it('uses memoized variables when variables are defined in terms of their previous values', function() {
      var count1, count2;
      count1 = 0;
      given({
        val1: function() {
          count1 += 1;
          return 1;
        }
      });

      count2 = 0;
      given({
        val1: function() {
          count2 += 1;
          return this.val1 + 1;
        }
      });

      expect(env.val1).to.equal(2);
      expect(count1).to.equal(1);
      expect(count2).to.equal(1);
    });

    it('forgets the memoization for all variables when any variable is redefined', function() {
      var count;
      count = 0;
      given({
        name: function() {
          count += 1;
          return 'James';
        }
      });

      expect(env.name).to.equal('James');
      expect(count).to.equal(1);
      given({
        age: function() {
          return 36;
        }
      });

      expect(env.name).to.equal('James');
      expect(count).to.equal(2);
    });

    it('exposes all defined properties as enumerable', function() {
      given({
        name: function() {
          return 'James';
        }
      });

      given({
        age: function() {
          return 36;
        }
      });

      given({
        occupation: function() {
          return 'programmer';
        }
      });

      expect(JSON.parse(JSON.stringify(env))).to.eql({
        name: 'James',
        age: 36,
        occupation: 'programmer'
      });

    });

    describe('is well-behaved and', function() {
      it('does not allow redefinition of "given"', function() {
        expect(function() {
          return given('given', 'anything');
        }).to.throwException(function(e) {
          expect(e.message).to.equal('cannot redefine given');
        });

      });

      it('gives a meaningful error when recursive definitions blow the stack', function() {
        given({
          a: function() {
            return this.b;
          }
        });

        given({
          b: function() {
            return this.a;
          }
        });

        expect(function() {
          return env.a;
        }).to.throwException(function(e) {
          expect(e.message).to.match(/recursive definition of variable '(a|b)' detected/);
        });

      });

      it('prevents the given environment from being referenced within a builder function', function() {
        given({
          foo: function() {
            return 'foo';
          }
        });

        given({
          viaThis: function() {
            return this.foo;
          }
        });

        given({
          viaEnv: function() {
            return env.foo;
          }
        });

        expect(env.viaThis).to.eql('foo');
        expect(function() {
          return env.viaEnv;
        }).to.throwException(function(e) {
          expect(e.message).to.equal("illegal attempt to access the Given environment in the definition of 'viaEnv'");
        });

      });

    });

```

### Coffee

```coffee

Given = require '../build/given'
expect = require 'expect.js'

describe "Given", ->

  given = env = undefined

  beforeEach ->
    env = Given.Env()
    given = env.given

  it "can define a variable", ->
    given 'name', 'James Sadler'
    expect(env.name).to.equal "James Sadler"

  it "can define a variable that is depends on another and is computed on demand", ->
    given 'name', 'James Sadler'
    given 'message', -> "Hello, #{@name}!"
    expect(env.message).to.equal 'Hello, James Sadler!'

  it 'can define variables in bulk', ->
    given
      name: 'James Sadler'
      age: 36
    expect(env.name).to.equal 'James Sadler'
    expect(env.age).to.equal 36

  it 'provides a way to explicitly clear the environment', ->
    given 'name', 'James Sadler'
    given.clear()
    expect(typeof env.name).to.be 'undefined'

  it 'can define variable in terms of the existing value', ->
    given 'array', -> [1]
    given 'array', -> @array.concat 2
    given 'array', -> @array.concat 3
    expect(env.array).to.eql [1, 2, 3]

  it 'supports the definition of variables that depend on a variable that is not yet defined', ->
    given foo: -> @bar
    given bar: -> 'Bar'
    expect(env.foo).to.equal 'Bar'

  # TODO better decscription please
  it 'supports the redefinition of', ->
    given name1: -> "James"
    given message: -> "#{@name1} and #{@name2}"
    given name2: -> "Kellie"
    expect(env.message).to.equal 'James and Kellie'

  it 'memoizes variables when they are evaluated', ->
    count = 0
    given name: ->
      count += 1
      'James'
    env.name
    expect(count).to.equal 1
    env.name
    expect(count).to.equal 1

  it 'uses memoized variables when variables are defined in terms of others', ->
    count = 0
    given val1: ->
      count += 1
      count
    given val2: ->
      @val1

    expect(env.val1).to.equal 1
    expect(env.val2).to.equal 1

  it 'uses memoized variables when variables are defined in terms of their previous values', ->
    count1 = 0
    given val1: ->
      count1 += 1
      1
    count2 = 0
    given val1: ->
      count2 += 1
      @val1 + 1

    expect(env.val1).to.equal 2
    expect(count1).to.equal 1
    expect(count2).to.equal 1

  it 'forgets the memoization for all variables when any variable is redefined', ->
    count = 0
    given name: ->
      count += 1
      'James'
    expect(env.name).to.equal 'James'
    expect(count).to.equal 1
    given age: -> 36
    expect(env.name).to.equal 'James'
    expect(count).to.equal 2

  it 'exposes all defined properties as enumerable', ->
    given name: -> 'James'
    given age: -> 36
    given occupation: -> 'programmer'
    expect(JSON.parse JSON.stringify env).to.eql
      name: 'James'
      age: 36
      occupation: 'programmer'

  describe 'is well-behaved and', ->

    it 'does not allow redefinition of "given"', ->
      expect(-> given 'given', 'anything').to.throwException (e) ->
        expect(e.message).to.equal 'cannot redefine given'

    it 'gives a meaningful error when recursive definitions blow the stack', ->
      given a: -> @b
      given b: -> @a
      expect(-> env.a).to.throwException (e) ->
        expect(e.message).to.match /recursive definition of variable '(a|b)' detected/

    it 'prevents the given environment from being referenced within a builder function', ->
      given foo: -> 'foo'
      given viaThis: -> @foo
      given viaEnv: -> env.foo
      expect(env.viaThis).to.eql 'foo'
      expect(-> env.viaEnv).to.throwException (e) ->
        expect(e.message).to.equal "illegal attempt to access the Given environment in the definition of 'viaEnv'"

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

1. Fork it ( https://github.com/freshtonic/given/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Licence

Copyright (c) 2014, given is developed and maintained by James Sadler, and is
released under the open MIT Licence.

