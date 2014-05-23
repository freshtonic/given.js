
class Env
  constructor: ->
    @vars = {}

  Let: (name, thing) ->
    if typeof thing is 'function'
      @vars[name] = thing
    else
      @vars[name] = -> thing

    Object.defineProperty @, name,
      get: @vars[name]
      enumerable: true

(module?.exports.Env = Env) or @Env = Env
