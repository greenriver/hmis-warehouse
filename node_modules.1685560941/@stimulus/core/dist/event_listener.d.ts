import { Binding } from "./binding";
export declare class EventListener implements EventListenerObject {
    readonly eventTarget: EventTarget;
    readonly eventName: string;
    readonly eventOptions: AddEventListenerOptions;
    private unorderedBindings;
    constructor(eventTarget: EventTarget, eventName: string, eventOptions: AddEventListenerOptions);
    connect(): void;
    disconnect(): void;
    /** @hidden */
    bindingConnected(binding: Binding): void;
    /** @hidden */
    bindingDisconnected(binding: Binding): void;
    handleEvent(event: Event): void;
    get bindings(): Binding[];
}
//# sourceMappingURL=event_listener.d.ts.map