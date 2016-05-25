
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
    var given;
    given = undefined;
    beforeEach(function() {
      given = Given(this);
    });

    it("can define a variable", function() {
      given('name', function() {
        return 'James Sadler';
      });

      expect(this.name).to.equal("James Sadler");
    });

    it("can define a variable that is depends on another and is computed on demand", function() {
      given('name', function() {
        return 'James Sadler';
      });

      given('message', function(env) {
        return "Hello, " + env.name + "!";
      });

      expect(this.message).to.equal('Hello, James Sadler!');
    });

    it('can define variables in bulk', function() {
      given({
        name: function() {
          return 'James Sadler';
        },
        age: function() {
          return 36;
        }
      });

      expect(this.name).to.equal('James Sadler');
      expect(this.age).to.equal(36);
    });

    it('can define a raw variable', function() {
      given.raw('name', 'James Sadler');
      expect(this.name).to.equal('James Sadler');
    });

    it('can define both raw and lazy variables in bulk', function() {
      given({
        name: given.raw('James Sadler'),
        age: function() {
          return 36;
        }
      });

      expect(this.name).to.equal('James Sadler');
      expect(this.age).to.equal(36);
    });

    it('provides a way to explicitly clear the environment', function() {
      given('name', function() {
        return 'James Sadler';
      });

      given.clear();
      expect(this.name).to.be(undefined);
    });

    it('can define variable in terms of the existing value', function() {
      given('array', function() {
        return [1];
      });

      given('array', function(env) {
        return env.array.concat(2);
      });

      given('array', function(env) {
        return env.array.concat(3);
      });

      expect(this.array).to.eql([1, 2, 3]);
    });

    it('supports the definition of variables that depend on a variable that is not yet defined', function() {
      given({
        foo: function(env) {
          return env.bar;
        }
      });

      given({
        bar: function() {
          return 'Bar';
        }
      });

      expect(this.foo).to.equal('Bar');
    });

    it('supports forward definitions', function() {
      given({
        name1: function() {
          return "James";
        }
      });

      given({
        message: function(env) {
          return env.name1 + " and " + env.name2;
        }
      });

      given({
        name2: function() {
          return "Kellie";
        }
      });

      expect(this.message).to.equal('James and Kellie');
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

      this.name;
      expect(count).to.equal(1);
      this.name;
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
        val2: function(env) {
          return env.val1;
        }
      });

      expect(this.val1).to.equal(1);
      expect(this.val2).to.equal(1);
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
        val1: function(env) {
          count2 += 1;
          return env.val1 + 1;
        }
      });

      expect(this.val1).to.equal(2);
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

      expect(this.name).to.equal('James');
      expect(count).to.equal(1);
      given({
        age: function() {
          return 36;
        }
      });

      expect(this.name).to.equal('James');
      expect(count).to.equal(2);
    });

    it('exposes all defined properties as enumerable', function() {
      var env;
      env = {};
      given = Given(env);
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

    describe('an edge case', function() {
      describe('when redefining a variable', function() {
        it('should not recompute the variable each time it is accessed in the new definition', function() {
          given({
            a: function() {
              return {
                name: 'James'
              };
            }
          });

          given({
            a: function(env) {
              env.a.name = 'foo';
              return env.a;
            }
          });

          expect(this.a.name).to.equal('foo');
        });

      });

    });

    describe('creating a function that caches computation of one specific instance variable', function() {
      var bind;
      bind = function(fn, self) {
        return function() {
          return fn.apply(self, arguments);
        };
      };
      it('lskfjlsf', function() {
        var boundFn, env, f, makeCachingEnv;
        env = {};
        Object.defineProperty(env, 'a', {
          get: function() {
            return {
              name: 'bar'
            };
          }
        });

        makeCachingEnv = function(env, name) {
          var cache, cachingEnv;
          cachingEnv = {};
          cache = undefined;
          return Object.defineProperty(cachingEnv, name, {
            get: function() {
              if (cache != null) {
                return cache;
              } else {
                return cache = env[name];
              }
            }
          });

        };
        f = function() {
          this.a.name = 'foo';
          return this.a;
        };
        boundFn = bind(f, makeCachingEnv(env, 'a'));
        expect(boundFn().name).to.equal('foo');
      });

    });

    describe('is well-behaved and', function() {
      it('gives a meaningful error message when the RHS is not a function', function() {
        expect(function() {
          given({
            foo: 'bar'
          });

        }).to.throwException(function(e) {
          expect(e.message).to.equal('definition of "foo" is not a function - did you mean to call `.raw`?');
        });

      });

      it('does not allow redefinition of "given"', function() {
        expect(function() {
          given('given', 'anything');
        }).to.throwException(function(e) {
          expect(e.message).to.equal('cannot redefine given');
        });

      });

      it('gives a meaningful error when recursive definitions blow the stack', function() {
        given({
          a: function(env) {
            return env.b;
          }
        });

        given({
          b: function(env) {
            return env.a;
          }
        });

        expect((function(_this) {
          return function() {
            return _this.a;
          };
        })(this)).to.throwException(function(e) {
          expect(e.message).to.match(/recursive definition of variable '(a|b)' detected/);
        });

      });

      describe('to avoid hard to track down bugs prevents the environment being referenced in a definition', function() {
        it('when the environment is not *this*', function() {
          var env;
          env = {};
          given = Given(env);
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

          expect((function(_this) {
            return function() {
              return env.viaThis;
            };
          })(this)).not.to.throwException();
          expect((function(_this) {
            return function() {
              return env.viaEnv;
            };
          })(this)).to.throwException(function(e) {
            expect(e.message).to.equal("Illegal attempt to use the Given environment object in the definition of 'viaEnv'; Use 'this' within value definitions.");
          });

        });

        it('when the environment is *this*', function() {
          given = Given(this);
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
            viaEnv: (function(_this) {
              return function() {
                return _this.foo;
              };
            })(this)
          });

          expect((function(_this) {
            return function() {
              return _this.viaThis;
            };
          })(this)).not.to.throwException();
          expect((function(_this) {
            return function() {
              return _this.viaEnv;
            };
          })(this)).to.throwException(function(e) {
            expect(e.message).to.equal("Illegal attempt to use the Given environment object in the definition of 'viaEnv'; Use 'this' within value definitions.");
          });

        });

      });

      describe("provides an isGiven function to identify objects created by Given", function() {
        it("returns true for the object returned by Given", function() {
          expect(Given.isGiven(new Given(this))).to.be(true);
        });

        it("returns true for any other object", function() {
          expect(Given.isGiven(new Object())).to.be(false);
        });

      });

    });

```

### Coffee

```coffee

Given = require '../build/given'
expect = require 'expect.js'

describe "Given", ->

  given = undefined

  beforeEach ->
    given = Given @

  it "can define a variable", ->
    given 'name', -> 'James Sadler'
    expect(@name).to.equal "James Sadler"

  it "can define a variable that is depends on another and is computed on demand", ->
    given 'name', -> 'James Sadler'
    given 'message', (env) -> "Hello, #{env.name}!"
    expect(@message).to.equal 'Hello, James Sadler!'

  it 'can define variables in bulk', ->
    given
      name: -> 'James Sadler'
      age: -> 36
    expect(@name).to.equal 'James Sadler'
    expect(@age).to.equal 36

  it 'can define a raw variable', ->
    given.raw 'name', 'James Sadler'
    expect(@name).to.equal 'James Sadler'

  it 'can define both raw and lazy variables in bulk', ->
    given
      name: given.raw('James Sadler')
      age: -> 36

    expect(@name).to.equal 'James Sadler'
    expect(@age).to.equal 36

  it 'provides a way to explicitly clear the environment', ->
    given 'name', -> 'James Sadler'
    given.clear()
    expect(@name).to.be undefined

  it 'can define variable in terms of the existing value', ->
    given 'array', -> [1]
    given 'array', (env) -> env.array.concat 2
    given 'array', (env) -> env.array.concat 3
    expect(@array).to.eql [1, 2, 3]

  it 'supports the definition of variables that depend on a variable that is not yet defined', ->
    given foo: (env) -> env.bar
    given bar: -> 'Bar'
    expect(@foo).to.equal 'Bar'

  it 'supports forward definitions', ->
    given name1: -> "James"
    given message: (env) -> "#{env.name1} and #{env.name2}"
    given name2: -> "Kellie"
    expect(@message).to.equal 'James and Kellie'

  it 'memoizes variables when they are evaluated', ->
    count = 0
    given name: ->
      count += 1
      'James'
    @name
    expect(count).to.equal 1
    @name
    expect(count).to.equal 1

  it 'uses memoized variables when variables are defined in terms of others', ->
    count = 0
    given val1: ->
      count += 1
      count
    given val2: (env) ->
      env.val1

    expect(@val1).to.equal 1
    expect(@val2).to.equal 1

  it 'uses memoized variables when variables are defined in terms of their previous values', ->
    count1 = 0
    given val1: ->
      count1 += 1
      1
    count2 = 0
    given val1: (env) ->
      count2 += 1
      env.val1 + 1

    expect(@val1).to.equal 2
    expect(count1).to.equal 1
    expect(count2).to.equal 1

  it 'forgets the memoization for all variables when any variable is redefined', ->
    count = 0
    given name: ->
      count += 1
      'James'
    expect(@name).to.equal 'James'
    expect(count).to.equal 1
    given age: -> 36
    expect(@name).to.equal 'James'
    expect(count).to.equal 2

  it 'exposes all defined properties as enumerable', ->
    env   = {}
    given = Given env

    given name: -> 'James'
    given age: -> 36
    given occupation: -> 'programmer'
    expect(JSON.parse JSON.stringify env).to.eql
      name: 'James'
      age: 36
      occupation: 'programmer'

  describe 'an edge case', ->

    describe 'when redefining a variable', ->

      it 'should not recompute the variable each time it is accessed in the new definition', ->

        given a: ->
          { name: 'James' }
        given a: (env) ->
          env.a.name = 'foo'
          env.a

        expect(@a.name).to.equal 'foo'

  describe 'creating a function that caches computation of one specific instance variable', ->
    bind = (fn, self) -> -> fn.apply self, arguments

    it 'lskfjlsf', ->

      env = {}
      Object.defineProperty env, 'a',
        get: -> { name: 'bar' }


      makeCachingEnv = (env, name) ->
        cachingEnv = {}
        cache = undefined
        Object.defineProperty cachingEnv, name,
          get: ->
            if cache?
              cache
            else
              cache = env[name]

      f = ->
        @a.name = 'foo'
        @a

      boundFn = bind f, makeCachingEnv(env, 'a')

      expect(boundFn().name).to.equal 'foo'

  describe 'is well-behaved and', ->

    it 'gives a meaningful error message when the RHS is not a function', ->
      expect(-> given foo: 'bar').to.throwException (e) ->
        expect(e.message).to.equal 'definition of "foo" is not a function - did you mean to call `.raw`?'

    it 'does not allow redefinition of "given"', ->
      expect(-> given 'given', 'anything').to.throwException (e) ->
        expect(e.message).to.equal 'cannot redefine given'

    it 'gives a meaningful error when recursive definitions blow the stack', ->
      given a: (env) -> env.b
      given b: (env) -> env.a
      expect(=> @a).to.throwException (e) ->
        expect(e.message).to.match /recursive definition of variable '(a|b)' detected/

    describe 'to avoid hard to track down bugs prevents the environment being referenced in a definition', ->

      it 'when the environment is not *this*', ->
        env   = {}
        given = Given env

        given foo:      -> 'foo'
        given viaThis:  -> @foo
        # 'this' is not used to reference values - the top most Given
        # environment is used instead.
        given viaEnv:   -> env.foo

        expect(=> env.viaThis).not.to.throwException()
        expect(=> env.viaEnv).to.throwException (e) ->
          expect(e.message).to.equal "
            Illegal attempt to use the Given environment object in the 
            definition of 'viaEnv'; Use 'this' within value definitions.
          "

      it 'when the environment is *this*', ->
        given = Given @

        given foo:      -> 'foo'
        given viaThis:  -> @foo
        # 'this' is bound to the *this* of the spec itself instead of the
        # environment under the control of Given.
        given viaEnv:   => @foo

        expect(=> @viaThis).not.to.throwException()
        expect(=> @viaEnv).to.throwException (e) ->
          expect(e.message).to.equal "
            Illegal attempt to use the Given environment object in the 
            definition of 'viaEnv'; Use 'this' within value definitions.
          "

    describe "provides an isGiven function to identify objects created by Given", ->
      it "returns true for the object returned by Given", ->
        expect(Given.isGiven(new Given @)).to.be true

      it "returns true for any other object", ->
        expect(Given.isGiven(new Object())).to.be false

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

