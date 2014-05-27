
env = require '../build/lazylet'

describe "lazylet usage", ->

  it "can define a variable", ->
    env.Let 'name', 'James Sadler'
    expect(env.name).toEqual "James Sadler"

  it "can define a variable that is depends on another and is computed on demand", ->
    env.Let 'name', 'James Sadler'
    env.Let 'message', -> "Hello, #{@name}!"
    expect(env.message).toEqual 'Hello, James Sadler!'

  it 'can define variables in bulk', ->
    env.Let
      name: 'James Sadler'
      age: 36
    expect(env.name).toEqual 'James Sadler'
    expect(env.age).toEqual 36

  it "does not clear the environment when declaring variables individually", ->
    env.Let 'name', 'James Sadler'
    env.Let 'age', 36
    expect(env.name).toEqual "James Sadler"
    expect(env.age).toEqual 36

  it "clears the environment when declaring variables in bulk", ->
    env.Let 'name', 'James Sadler'
    env.Let 'age', 36
    env.Let
      name: 'James Sadler'
    expect(typeof env.age).toBe 'undefined'

  it 'can bulk-declare variables without clearing the environment', ->
    env.Let 'name', 'James Sadler'
    env.Let 'age', 36
    env.Let.preserve
      name: 'James Sadler'
    expect(env.age).toBe 36

  it 'provides a way to explicitly clear the environment', ->
    env.Let 'name', 'James Sadler'
    env.Let.clear()
    expect(typeof env.name).toBe 'undefined'

  it 'can define variable in terms of the existing value', ->
    env.Let 'array', [1, 2, 3]
    env.Let 'array', ->
      @array.concat 4
    expect(env.array).toEqual [1, 2, 3, 4]

  describe 'behaving in sane manner', ->

    it 'does not allow redefinition of "Let"', ->
      expect(-> env.Let 'Let', 'anything').toThrow 'cannot redefine Let'

    it 'does not allow Let to be directly overwritten', ->
      env.Let = 'something else'
      expect(typeof env.Let).toEqual 'function'

