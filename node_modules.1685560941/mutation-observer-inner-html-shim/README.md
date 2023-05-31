In IE 11, nodes in `MutationRecord.removedNodes` are always empty when they're removed by setting `innerHTML`. This shim works around the issue by patching `HTMLElement.innerHTML` to remove each child node individually before setting the new value.

References:
* https://connect.microsoft.com/IE/feedback/details/817132/ie-11-childnodes-are-missing-from-mutationobserver-mutations-removednodes-after-setting-innerhtml
* https://github.com/WebReflection/document-register-element/issues/101
* https://github.com/skatejs/skatejs/issues/85
