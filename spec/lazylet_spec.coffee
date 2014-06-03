
LazyLet = require '../build/lazylet'

describe "lazylet usage", ->

  Let = env = undefined

  beforeEach ->
    env = LazyLet.Env()
    Let = env.Let

  it "can define a variable", ->
    Let 'name', 'James Sadler'
    expect(env.name).toEqual "James Sadler"

  it "can define a variable that is depends on another and is computed on demand", ->
    Let 'name', 'James Sadler'
    Let 'message', -> "Hello, #{@name}!"
    expect(env.message).toEqual 'Hello, James Sadler!'

  it 'can define variables in bulk', ->
    Let
      name: 'James Sadler'
      age: 36
    expect(env.name).toEqual 'James Sadler'
    expect(env.age).toEqual 36

  it "does not clear the environment when declaring variables individually", ->
    Let 'name', 'James Sadler'
    Let 'age', 36
    expect(env.name).toEqual "James Sadler"
    expect(env.age).toEqual 36

  it 'provides a way to explicitly clear the environment', ->
    Let 'name', 'James Sadler'
    Let.clear()
    expect(typeof env.name).toBe 'undefined'

  it 'can define variable in terms of the existing value', ->
    Let 'array', -> [1]
    Let 'array', -> @array.concat 2
    Let 'array', -> @array.concat 3
    expect(env.array).toEqual [1, 2, 3]

  it 'supports the definition of variables that depend on a variable that is not yet defined', ->
    Let foo: -> @bar
    Let bar: -> 'Bar'
    expect(env.foo).toEqual 'Bar'

  it 'supports the redefinition of', ->
    Let name1: -> "James"
    Let message: -> "#{@name1} #{@name2}"
    Let name2: -> "Kellie"

  it 'memoizes variables when they are evaluated', ->
    count = 0
    Let name: ->
      count += 1
      'James'
    env.name
    expect(count).toEqual 1
    env.name
    expect(count).toEqual 1

  it 'uses memoized variables when variables are defined in terms of others', ->
    count = 0
    Let val1: ->
      count += 1
      count
    Let val2: ->
      @val1

    expect(env.val1).toEqual 1
    expect(env.val2).toEqual 1

  it 'uses memoized variables when variables are defined in terms of their previous values', ->
    count1 = 0
    Let val1: ->
      count1 += 1
      1
    count2 = 0
    Let val1: ->
      count2 += 1
      @val1 + 1

    expect(env.val1).toEqual 2
    expect(count1).toEqual 1
    expect(count2).toEqual 1

  it 'forgets the memoization for all variables when any variable is redefined', ->
    count = 0
    Let name: ->
      count += 1
      'James'
    expect(env.name).toEqual 'James'
    expect(count).toEqual 1
    Let age: -> 36
    expect(env.name).toEqual 'James'
    expect(count).toEqual 2

  it 'exposes all defined properties as enumerable', ->
    Let name: -> 'James'
    Let age: -> 36
    Let occupation: -> 'programmer'
    expect(JSON.parse JSON.stringify env).toEqual
      name: 'James'
      age: 36
      occupation: 'programmer'


  describe 'behaving in sane manner', ->

    it 'does not allow redefinition of "Let"', ->
      expect(-> Let 'Let', 'anything').toThrow 'cannot redefine Let'

