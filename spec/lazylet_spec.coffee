
Env = require('../build/lazylet').Env

describe "lazylet", ->

  env = undefined

  beforeEach ->
    env = new Env()
    env.Let 'name', "James Sadler"

  it "can define a variable", ->
    expect(env.name).toEqual "James Sadler"

  it "can define a variable that depends on another one", ->
    env.Let 'message', -> "#{@name} likes to write code"
    expect(env.message).toEqual "James Sadler likes to write code"

  xit "allows redefinition of existing variables", ->
    env.Let 'name', 'Matt Allen'
    expect(env.message).toEqual "Matt Allen likes to write code"

