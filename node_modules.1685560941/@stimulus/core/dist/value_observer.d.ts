import { Context } from "./context";
import { StringMapObserverDelegate } from "@stimulus/mutation-observers";
export declare class ValueObserver implements StringMapObserverDelegate {
    readonly context: Context;
    readonly receiver: any;
    private stringMapObserver;
    private valueDescriptorMap;
    constructor(context: Context, receiver: any);
    start(): void;
    stop(): void;
    get element(): Element;
    get controller(): import("./controller").Controller;
    getStringMapKeyForAttribute(attributeName: string): string | undefined;
    stringMapValueChanged(attributeValue: string | null, name: string): void;
    private invokeChangedCallbacksForDefaultValues;
    private invokeChangedCallbackForValue;
    private get valueDescriptors();
}
//# sourceMappingURL=value_observer.d.ts.map