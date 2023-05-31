import { Constructor } from "./constructor";
/** @hidden */
export declare function ValuePropertiesBlessing<T>(constructor: Constructor<T>): PropertyDescriptorMap;
/** @hidden */
export declare function propertiesForValueDefinitionPair<T>(valueDefinitionPair: ValueDefinitionPair): PropertyDescriptorMap;
export declare type ValueDescriptor = {
    type: ValueType;
    key: string;
    name: string;
    defaultValue: any;
};
export declare type ValueDescriptorMap = {
    [attributeName: string]: ValueDescriptor;
};
export declare type ValueDefinitionMap = {
    [token: string]: ValueTypeConstant;
};
export declare type ValueDefinitionPair = [string, ValueTypeConstant];
export declare type ValueTypeConstant = typeof Array | typeof Boolean | typeof Number | typeof Object | typeof String;
export declare type ValueType = "array" | "boolean" | "number" | "object" | "string";
//# sourceMappingURL=value_properties.d.ts.map