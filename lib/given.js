// Generated by CoffeeScript 1.7.1
(function() {
  var Given, bind, defineGetter,
    __hasProp = {}.hasOwnProperty;

  bind = function(fn, self) {
    return function() {
      return fn.apply(self, arguments);
    };
  };

  defineGetter = function(obj, name, fn) {
    return Object.defineProperty(obj, name, {
      get: fn,
      configurable: true,
      enumerable: true
    });
  };

  Given = function(self) {
    var define, defineInBulk, defineOneVariable, definitionCount, entered, env, failOnReenter, funs, given, isFirstDefinitionOf, isStackOverflowError, memoize, memos, privateEnv, redefine, resetEnv, topmostVariableBeingEvaluated, trapOuterEnvAccess, trapStackOverflow;
    privateEnv = {};
    env = self || {};
    funs = {};
    memos = {};
    definitionCount = 0;
    topmostVariableBeingEvaluated = void 0;
    entered = function() {
      return topmostVariableBeingEvaluated != null;
    };
    failOnReenter = function(name) {
      return function() {
        if (entered()) {
          throw new Error("Illegal attempt to use the Given environment object in the definition of '" + topmostVariableBeingEvaluated + "'; Use 'this' within value definitions.");
        } else {
          return privateEnv[name];
        }
      };
    };
    resetEnv = function() {
      var name;
      for (name in privateEnv) {
        if (!__hasProp.call(privateEnv, name)) continue;
        if (name !== 'given') {
          delete env[name];
        }
      }
      funs = {};
      memos = {};
      privateEnv = {};
      return definitionCount = 0;
    };
    memoize = function(key) {
      return function(fn) {
        var memo;
        memo = memos[key];
        if (memo != null) {
          return memo;
        } else {
          return memos[key] = fn();
        }
      };
    };
    isStackOverflowError = function(err) {
      var message;
      message = (typeof err === 'string' ? err : err != null ? err.message : void 0) || '';
      return message.match(/\bstack|recursion\b/);
    };
    trapStackOverflow = function(name) {
      return function(fn) {
        var err;
        try {
          return fn();
        } catch (_error) {
          err = _error;
          if (isStackOverflowError(err)) {
            throw new Error("recursive definition of variable '" + name + "' detected");
          } else {
            throw err;
          }
        }
      };
    };
    trapOuterEnvAccess = function(name) {
      return function(fn) {
        topmostVariableBeingEvaluated = name;
        try {
          return fn();
        } finally {
          topmostVariableBeingEvaluated = void 0;
        }
      };
    };
    redefine = function(name, fn) {
      var newEnv, newFn, oldFn;
      newEnv = Object.create(privateEnv);
      oldFn = funs[name];
      defineGetter(newEnv, name, bind(oldFn, privateEnv));
      newFn = define(newEnv, fn, name);
      defineGetter(privateEnv, name, newFn);
      return newFn;
    };
    define = function(env, definitionFn, name) {
      var f1, f2, f3, f4;
      definitionCount += 1;
      f1 = bind(definitionFn, env);
      f2 = trapStackOverflow(name);
      f3 = trapOuterEnvAccess(name);
      f4 = memoize("" + name + "_" + definitionCount);
      return function() {
        return f4(function() {
          return f3(function() {
            return f2(function() {
              return f1();
            });
          });
        });
      };
    };
    isFirstDefinitionOf = function(name) {
      return funs[name] == null;
    };
    defineOneVariable = function(name, definitionFn) {
      if (name === 'given') {
        throw new Error('cannot redefine given');
      }
      if (!(definitionFn instanceof Function)) {
        throw new Error("definition of \"" + name + "\" is not a function");
      }
      memos = {};
      if (isFirstDefinitionOf(name)) {
        funs[name] = define(privateEnv, definitionFn, name);
        defineGetter(privateEnv, name, funs[name]);
        return defineGetter(env, name, failOnReenter(name));
      } else {
        return funs[name] = redefine(name, definitionFn);
      }
    };
    defineInBulk = function(definitions) {
      var definition, name, _results;
      _results = [];
      for (name in definitions) {
        if (!__hasProp.call(definitions, name)) continue;
        definition = definitions[name];
        _results.push(defineOneVariable(name, definition));
      }
      return _results;
    };
    given = function() {
      var args, name, thing;
      args = [].slice.apply(arguments);
      if (typeof args[0] === 'object') {
        return defineInBulk(args[0]);
      } else {
        name = args[0], thing = args[1];
        return defineOneVariable(name, thing);
      }
    };
    Object.defineProperties(given, {
      clear: {
        writable: false,
        configurable: false,
        value: resetEnv
      },
      __isGiven__: {
        writable: false,
        configurable: false,
        value: true
      }
    });
    return given;
  };

  Given.isGiven = function(obj) {
    return (obj != null ? obj.__isGiven__ : void 0) || false;
  };

  if ((typeof module !== 'undefined') && (module.exports != null)) {
    module.exports = Given;
  } else {
    this.Given = Given;
  }

}).call(this);
