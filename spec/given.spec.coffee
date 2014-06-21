
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

