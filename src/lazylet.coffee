
LazyLet =
  Env: ->
    env = {}
    top = {}
    vars = {}

    resetEnv = ->
      vars = {}
      top = {}
      for name in Object.keys(env) when name isnt 'Let'
        delete env[name]

    defineOneVariable = (name, valueOrFn) ->
      throw 'cannot redefine Let' if name is 'Let'
      fn = undefined
      if typeof valueOrFn is 'function'
        fn = valueOrFn.bind top
      else
        fn = -> valueOrFn

      current = vars[name] or (->)
      vars[name] = -> fn current()

      top = Object.create top

      Object.defineProperty top, name,
        get: vars[name]
        configurable: true
        enumerable: true

      Object.defineProperty env, name,
        get: -> top[name]
        configurable: true
        enumerable: true

    defineInBulk = (object) ->
      for name, thing of object
        defineOneVariable name, thing

    # The arguments to this function are (name, thing) or (object).
    # The second form is for defining variables in bulk.
    Let = ->
      args = [].slice.apply arguments
      if typeof args[0] is 'object'
        defineInBulk args[0]
      else
        [name, thing] = args
        defineOneVariable name, thing

    Object.defineProperty env, 'Let',
      writable: false
      configurable: false
      value: Let

    Object.defineProperties Let,
      clear:
        writable: false
        configurable: false
        value: resetEnv

    env

(module?.exports = LazyLet) or @LazyLet = LazyLet
