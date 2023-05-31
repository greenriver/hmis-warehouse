import { Constructor } from "./constructor";
/** @hidden */
export declare type Blessing<T> = (constructor: Constructor<T>) => PropertyDescriptorMap;
/** @hidden */
export interface Blessable<T> extends Constructor<T> {
    readonly blessings?: Blessing<T>[];
}
/** @hidden */
export declare function bless<T>(constructor: Blessable<T>): Constructor<T>;
//# sourceMappingURL=blessing.d.ts.map