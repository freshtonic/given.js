
# Function.prototype.bind is absent in PhantomJS. Implement it ourselves.
bind = (fn, self) ->
  -> fn.apply self, arguments

LazyLet =
  Env: ->
    env = {}
    top = {}
    lazyFns = {}
    memos = {}

    resetEnv = ->
      lazyFns = {}
      top = {}
      memos = {}
      for name in Object.keys(env) when name isnt 'Let'
        delete env[name]

    defineOneVariable = (name, valueOrFn) ->
      throw 'cannot redefine Let' if name is 'Let'

      if typeof valueOrFn is 'function'
        fn = bind valueOrFn, top
      else
        fn = -> valueOrFn

      lazyFns[name] = ->
        if memos[name]?
          memos[name]
        else
          memos[name] = fn()

      top = Object.create top

      memos = {}

      Object.defineProperty top, name,
        get: lazyFns[name]
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
