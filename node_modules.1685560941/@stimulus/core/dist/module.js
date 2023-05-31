import { Context } from "./context";
import { blessDefinition } from "./definition";
var Module = /** @class */ (function () {
    function Module(application, definition) {
        this.application = application;
        this.definition = blessDefinition(definition);
        this.contextsByScope = new WeakMap;
        this.connectedContexts = new Set;
    }
    Object.defineProperty(Module.prototype, "identifier", {
        get: function () {
            return this.definition.identifier;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Module.prototype, "controllerConstructor", {
        get: function () {
            return this.definition.controllerConstructor;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Module.prototype, "contexts", {
        get: function () {
            return Array.from(this.connectedContexts);
        },
        enumerable: false,
        configurable: true
    });
    Module.prototype.connectContextForScope = function (scope) {
        var context = this.fetchContextForScope(scope);
        this.connectedContexts.add(context);
        context.connect();
    };
    Module.prototype.disconnectContextForScope = function (scope) {
        var context = this.contextsByScope.get(scope);
        if (context) {
            this.connectedContexts.delete(context);
            context.disconnect();
        }
    };
    Module.prototype.fetchContextForScope = function (scope) {
        var context = this.contextsByScope.get(scope);
        if (!context) {
            context = new Context(this, scope);
            this.contextsByScope.set(scope, context);
        }
        return context;
    };
    return Module;
}());
export { Module };
//# sourceMappingURL=module.js.map