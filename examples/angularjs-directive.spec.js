
// === File: my-message-widget.js

angular.module('my-module').directive('myMessageWidget', function() {
  return {
    scope: {
      message: '='
    },
    replace: true,
    restrict: 'E',
    template: "&lt;span class='my-message'&gt;{{ message }}&lt;/span&gt;"
  };
});

// === File: directive-spec-boilerplate.module.js

// Define a module containing the definition of a Given environment for testing
// Angular directives.
angular.module('directive-spec-boilerplate', []).service 'directiveSpec', function($compile, $rootScope) {
  return function(spec) {
    var given = Given(spec);

    given({

      // Returns a compiled and linked HTML element.
      element: function() {
        var element = angular.element(this.template);
        $compile(element)(this.scopeObject);
        scopeObject.$digest();
        return element;
      },

      // The Angular scope.
      scopeObject: function() {
        var scope = $rootScope.$new();
        if (this.scope) {
          _.extend(scope, this.scope);
        }
        return scope;
      },

      // Returns the element's isolated scope.
      isolateScope: function() {
        return this.element.isolateScope();
      },

      // Defines your template. This is just a placeholder. If you forget to
      // override the definition in your own spec, it will error out with
      // a helpful message.
      template: function() {
        throw new Error 'You must override the "template" definition to define your template'
      }
    });

    return given;
  };
};

// === File: my-message-widget.spec.js

// Then make use of it in your spec for your directive.
describe('Directive: myMessageWidget', function() {

  var given = undefined;

  beforeEach(function() {
    module('my-module');
    module('directive-spec-boilerplate');
  });

  beforeEach(inject(function(directiveSpec) {

    // Creates the Given environment, pre-populated with Angular JS directive
    // spec boilerplate. The 'this' is the 'this' of the spec itself, which
    // means all variables defined via given are actually properties of the
    // spec.
    given = directiveSpec(this);

    given({

      template: function() {
        return '<my-message-widget message="message"></my-message-widget>';
      },

      scope: function() {
        return { message: "Hello from James!" };
      }

    });

  }));

  it('displays the message', function() {
    // Accessing 'this.element' causes lazy evaluation of the element as defined
    // in the boilerplate helper.
    expect(this.element.find(".my-message")).toHaveText('Hello from James!');
  });

});
