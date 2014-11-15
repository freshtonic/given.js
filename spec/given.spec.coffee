
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
    given 'message', -> "Hello, #{@name}!"
    expect(@message).to.equal 'Hello, James Sadler!'

  it 'can define variables in bulk', ->
    given
      name: -> 'James Sadler'
      age: -> 36
    expect(@name).to.equal 'James Sadler'
    expect(@age).to.equal 36

  it 'provides a way to explicitly clear the environment', ->
    given 'name', -> 'James Sadler'
    given.clear()
    expect(@name).to.be undefined

  it 'can define variable in terms of the existing value', ->
    given 'array', -> [1]
    given 'array', -> @array.concat 2
    given 'array', -> @array.concat 3
    expect(@array).to.eql [1, 2, 3]

  it 'supports the definition of variables that depend on a variable that is not yet defined', ->
    given foo: -> @bar
    given bar: -> 'Bar'
    expect(@foo).to.equal 'Bar'

  it 'supports forward definitions', ->
    given name1: -> "James"
    given message: -> "#{@name1} and #{@name2}"
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
    given val2: ->
      @val1

    expect(@val1).to.equal 1
    expect(@val2).to.equal 1

  it 'uses memoized variables when variables are defined in terms of their previous values', ->
    count1 = 0
    given val1: ->
      count1 += 1
      1
    count2 = 0
    given val1: ->
      count2 += 1
      @val1 + 1

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
        given a: ->
          @a.name = 'foo'
          @a

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
        expect(e.message).to.equal 'definition of "foo" is not a function'

    it 'does not allow redefinition of "given"', ->
      expect(-> given 'given', 'anything').to.throwException (e) ->
        expect(e.message).to.equal 'cannot redefine given'

    it 'gives a meaningful error when recursive definitions blow the stack', ->
      given a: -> @b
      given b: -> @a
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

      it 'wnen the environment is *this*', ->
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

