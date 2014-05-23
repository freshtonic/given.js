
# lazylet

*lazylet* is a lazy-evaluation system for use in your specs.

Variables are defined within an environment object and are lazily computed on
demand. A variable can hold either a value, function or object. If the variable
is a function it used for computing the value of the variable when it is
accessed from the environment.

Variables are accessed from the environment as if they are plain JS properties.
Under the hood, the properties are defined using Object.defineProperty with
a 'get' accessor in order that their value can be computed on demand.


# Usage

```javascript
var Env = require('let').Env;

describe('My test', function(){

    var Let = undefined;

    beforeEach(function() {
        env = new Env();
        env.Let('name', 'James');
        env.Let('campJsNumber', 3);
        env.Let('message', function() {
            return "Welcome, " + this.name + ", from CampJS " + this.campJsNumber;
        });
    });

    it("should produce the expected message", function(){
        expect(env.message).to.equal("Welcome, James, from CampJS 3");
    });

    it("should use redefined variables", function(){
        env.Let('name', function() { return "@freshtonic"; });
        expect(env.message).to.equal("Welcome, @freshtonic, from CampJS 3");
    });
});
```

# Caveats

To set a variable with a value that *is* a function, nest it within
another function (to avoid ambiguity with dynamically computing a value), like so:

```javascript

env.Let('aFunction', function() {
    // This function will be the variable's value.
    return function() {
        return 'foo';
    };
});

```
