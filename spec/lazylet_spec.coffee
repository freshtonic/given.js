
Env = require('../build/lazylet').Env

describe "lazylet", ->

  env = undefined

  beforeEach ->
    env = new Env()
    env.Let 'name', "James Sadler"
    env.Let 'message', -> "#{@name} likes to write code"

  it "can define a variable", ->
    expect(env.name).toEqual "James Sadler"

  it "can define a variable that depends on another one", ->
    expect(env.message).toEqual "James Sadler likes to write code"

  describe 'redefinition of existing variables', ->

    beforeEach ->
      env.Let 'name', 'Matt Allen'

    it "works for the simple case", ->
      expect(env.name).toEqual 'Matt Allen'

    it "works for the derived case", ->
      expect(env.message).toEqual "Matt Allen likes to write code"

