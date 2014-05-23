
class Env
  constructor: ->
    @vars = {}

  Object.defineProperty @::, 'Let',
    writable: false
    configurable: false
    value: (name, thing) ->
      throw 'cannot redefine Let' if name is 'Let'
      if typeof thing is 'function'
        @vars[name] = thing.bind @
      else
        @vars[name] = => thing

      Object.defineProperty @, name,
        get: -> @vars[name]()
        configurable: true

(module?.exports.Env = Env) or @Env = Env
