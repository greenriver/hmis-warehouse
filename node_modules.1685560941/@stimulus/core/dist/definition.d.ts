import { ControllerConstructor } from "./controller";
export interface Definition {
    identifier: string;
    controllerConstructor: ControllerConstructor;
}
/** @hidden */
export declare function blessDefinition(definition: Definition): Definition;
//# sourceMappingURL=definition.d.ts.map