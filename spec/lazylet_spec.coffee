
LazyLet = require '../build/lazylet'
expect = require 'expect.js'

describe "LazyLet", ->

  Let = env = undefined

  beforeEach ->
    env = LazyLet.Env()
    Let = env.Let

  it "can define a variable", ->
    Let 'name', 'James Sadler'
    expect(env.name).to.equal "James Sadler"

  it "can define a variable that is depends on another and is computed on demand", ->
    Let 'name', 'James Sadler'
    Let 'message', -> "Hello, #{@name}!"
    expect(env.message).to.equal 'Hello, James Sadler!'

  it 'can define variables in bulk', ->
    Let
      name: 'James Sadler'
      age: 36
    expect(env.name).to.equal 'James Sadler'
    expect(env.age).to.equal 36

  it 'provides a way to explicitly clear the environment', ->
    Let 'name', 'James Sadler'
    Let.clear()
    expect(typeof env.name).to.be 'undefined'

  it 'can define variable in terms of the existing value', ->
    Let 'array', -> [1]
    Let 'array', -> @array.concat 2
    Let 'array', -> @array.concat 3
    expect(env.array).to.eql [1, 2, 3]

  it 'supports the definition of variables that depend on a variable that is not yet defined', ->
    Let foo: -> @bar
    Let bar: -> 'Bar'
    expect(env.foo).to.equal 'Bar'

  # TODO better decscription please
  it 'supports the redefinition of', ->
    Let name1: -> "James"
    Let message: -> "#{@name1} and #{@name2}"
    Let name2: -> "Kellie"
    expect(env.message).to.equal 'James and Kellie'

  it 'memoizes variables when they are evaluated', ->
    count = 0
    Let name: ->
      count += 1
      'James'
    env.name
    expect(count).to.equal 1
    env.name
    expect(count).to.equal 1

  it 'uses memoized variables when variables are defined in terms of others', ->
    count = 0
    Let val1: ->
      count += 1
      count
    Let val2: ->
      @val1

    expect(env.val1).to.equal 1
    expect(env.val2).to.equal 1

  it 'uses memoized variables when variables are defined in terms of their previous values', ->
    count1 = 0
    Let val1: ->
      count1 += 1
      1
    count2 = 0
    Let val1: ->
      count2 += 1
      @val1 + 1

    expect(env.val1).to.equal 2
    expect(count1).to.equal 1
    expect(count2).to.equal 1

  it 'forgets the memoization for all variables when any variable is redefined', ->
    count = 0
    Let name: ->
      count += 1
      'James'
    expect(env.name).to.equal 'James'
    expect(count).to.equal 1
    Let age: -> 36
    expect(env.name).to.equal 'James'
    expect(count).to.equal 2

  it 'exposes all defined properties as enumerable', ->
    Let name: -> 'James'
    Let age: -> 36
    Let occupation: -> 'programmer'
    expect(JSON.parse JSON.stringify env).to.eql
      name: 'James'
      age: 36
      occupation: 'programmer'

  describe 'is well-behaved and', ->

    it 'does not allow redefinition of "Let"', ->
      expect(-> Let 'Let', 'anything').to.throwException (e) ->
        expect(e).to.equal 'cannot redefine Let'

    it 'gives a meaningful error when recursive definitions blow the stack', ->
      Let a: -> @b
      Let b: -> @a
      expect(-> env.a).to.throwException (e) ->
        expect(e).to.match /recursive definition of variable '(a|b)' detected/

    it 'prevents the Let environment from being referenced within a builder function', ->
      Let foo: -> 'foo'
      Let viaThis: -> @foo
      Let viaEnv: -> env.foo
      expect(env.viaThis).to.eql 'foo'
      expect(-> env.viaEnv).to.throwException (e) ->
        expect(e).to.equal "illegal attempt to access the Let environment in the definition of 'viaEnv'"

