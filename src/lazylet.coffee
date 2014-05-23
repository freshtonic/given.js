
class Env
  constructor: ->
    @vars = {}

  Let: (name, thing) ->
    if typeof thing is 'function'
      @vars[name] = thing.bind @
    else
      @vars[name] = => thing

    Object.defineProperty @, name,
      get: -> @vars[name]()
      configurable: true

(module?.exports.Env = Env) or @Env = Env
