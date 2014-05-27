
env = {}
vars = {}

resetEnv = ->
  vars = {}
  for name in Object.keys(env) when name isnt 'Let'
    delete env[name]

defineOneVariable = (name, thing) ->
  throw 'cannot redefine Let' if name is 'Let'
  if typeof thing is 'function'
    vars[name] = thing.bind env
  else
    vars[name] = -> thing

  Object.defineProperty env, name,
    get: -> vars[name]()
    configurable: true
    enumerable: true

defineInBulk = (object, preserve=false) ->
  resetEnv() if not preserve
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

Let.preserve = (object) ->
  defineInBulk object, true

Let.clear = ->
  resetEnv()

Object.defineProperty env, 'Let',
  writable: false
  configurable: false
  value: Let

(module?.exports = env) or @env = env
