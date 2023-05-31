import { bless } from "./blessing";
/** @hidden */
export function blessDefinition(definition) {
    return {
        identifier: definition.identifier,
        controllerConstructor: bless(definition.controllerConstructor)
    };
}
//# sourceMappingURL=definition.js.map