(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
  typeof define === 'function' && define.amd ? define(['exports'], factory) :
  (global = global || self, factory(global.CableReady = {}));
}(this, (function (exports) {
  var DOCUMENT_FRAGMENT_NODE = 11;

  function morphAttrs(fromNode, toNode) {
    var toNodeAttrs = toNode.attributes;
    var attr;
    var attrName;
    var attrNamespaceURI;
    var attrValue;
    var fromValue; // document-fragments dont have attributes so lets not do anything

    if (toNode.nodeType === DOCUMENT_FRAGMENT_NODE || fromNode.nodeType === DOCUMENT_FRAGMENT_NODE) {
      return;
    } // update attributes on original DOM element


    for (var i = toNodeAttrs.length - 1; i >= 0; i--) {
      attr = toNodeAttrs[i];
      attrName = attr.name;
      attrNamespaceURI = attr.namespaceURI;
      attrValue = attr.value;

      if (attrNamespaceURI) {
        attrName = attr.localName || attrName;
        fromValue = fromNode.getAttributeNS(attrNamespaceURI, attrName);

        if (fromValue !== attrValue) {
          if (attr.prefix === 'xmlns') {
            attrName = attr.name; // It's not allowed to set an attribute with the XMLNS namespace without specifying the `xmlns` prefix
          }

          fromNode.setAttributeNS(attrNamespaceURI, attrName, attrValue);
        }
      } else {
        fromValue = fromNode.getAttribute(attrName);

        if (fromValue !== attrValue) {
          fromNode.setAttribute(attrName, attrValue);
        }
      }
    } // Remove any extra attributes found on the original DOM element that
    // weren't found on the target element.


    var fromNodeAttrs = fromNode.attributes;

    for (var d = fromNodeAttrs.length - 1; d >= 0; d--) {
      attr = fromNodeAttrs[d];
      attrName = attr.name;
      attrNamespaceURI = attr.namespaceURI;

      if (attrNamespaceURI) {
        attrName = attr.localName || attrName;

        if (!toNode.hasAttributeNS(attrNamespaceURI, attrName)) {
          fromNode.removeAttributeNS(attrNamespaceURI, attrName);
        }
      } else {
        if (!toNode.hasAttribute(attrName)) {
          fromNode.removeAttribute(attrName);
        }
      }
    }
  }

  var range; // Create a range object for efficently rendering strings to elements.

  var NS_XHTML = 'http://www.w3.org/1999/xhtml';
  var doc = typeof document === 'undefined' ? undefined : document;
  var HAS_TEMPLATE_SUPPORT = !!doc && 'content' in doc.createElement('template');
  var HAS_RANGE_SUPPORT = !!doc && doc.createRange && 'createContextualFragment' in doc.createRange();

  function createFragmentFromTemplate(str) {
    var template = doc.createElement('template');
    template.innerHTML = str;
    return template.content.childNodes[0];
  }

  function createFragmentFromRange(str) {
    if (!range) {
      range = doc.createRange();
      range.selectNode(doc.body);
    }

    var fragment = range.createContextualFragment(str);
    return fragment.childNodes[0];
  }

  function createFragmentFromWrap(str) {
    var fragment = doc.createElement('body');
    fragment.innerHTML = str;
    return fragment.childNodes[0];
  }
  /**
   * This is about the same
   * var html = new DOMParser().parseFromString(str, 'text/html');
   * return html.body.firstChild;
   *
   * @method toElement
   * @param {String} str
   */


  function toElement(str) {
    str = str.trim();

    if (HAS_TEMPLATE_SUPPORT) {
      // avoid restrictions on content for things like `<tr><th>Hi</th></tr>` which
      // createContextualFragment doesn't support
      // <template> support not available in IE
      return createFragmentFromTemplate(str);
    } else if (HAS_RANGE_SUPPORT) {
      return createFragmentFromRange(str);
    }

    return createFragmentFromWrap(str);
  }
  /**
   * Returns true if two node's names are the same.
   *
   * NOTE: We don't bother checking `namespaceURI` because you will never find two HTML elements with the same
   *       nodeName and different namespace URIs.
   *
   * @param {Element} a
   * @param {Element} b The target element
   * @return {boolean}
   */


  function compareNodeNames(fromEl, toEl) {
    var fromNodeName = fromEl.nodeName;
    var toNodeName = toEl.nodeName;
    var fromCodeStart, toCodeStart;

    if (fromNodeName === toNodeName) {
      return true;
    }

    fromCodeStart = fromNodeName.charCodeAt(0);
    toCodeStart = toNodeName.charCodeAt(0); // If the target element is a virtual DOM node or SVG node then we may
    // need to normalize the tag name before comparing. Normal HTML elements that are
    // in the "http://www.w3.org/1999/xhtml"
    // are converted to upper case

    if (fromCodeStart <= 90 && toCodeStart >= 97) {
      // from is upper and to is lower
      return fromNodeName === toNodeName.toUpperCase();
    } else if (toCodeStart <= 90 && fromCodeStart >= 97) {
      // to is upper and from is lower
      return toNodeName === fromNodeName.toUpperCase();
    } else {
      return false;
    }
  }
  /**
   * Create an element, optionally with a known namespace URI.
   *
   * @param {string} name the element name, e.g. 'div' or 'svg'
   * @param {string} [namespaceURI] the element's namespace URI, i.e. the value of
   * its `xmlns` attribute or its inferred namespace.
   *
   * @return {Element}
   */


  function createElementNS(name, namespaceURI) {
    return !namespaceURI || namespaceURI === NS_XHTML ? doc.createElement(name) : doc.createElementNS(namespaceURI, name);
  }
  /**
   * Copies the children of one DOM element to another DOM element
   */


  function moveChildren(fromEl, toEl) {
    var curChild = fromEl.firstChild;

    while (curChild) {
      var nextChild = curChild.nextSibling;
      toEl.appendChild(curChild);
      curChild = nextChild;
    }

    return toEl;
  }

  function syncBooleanAttrProp(fromEl, toEl, name) {
    if (fromEl[name] !== toEl[name]) {
      fromEl[name] = toEl[name];

      if (fromEl[name]) {
        fromEl.setAttribute(name, '');
      } else {
        fromEl.removeAttribute(name);
      }
    }
  }

  var specialElHandlers = {
    OPTION: function OPTION(fromEl, toEl) {
      var parentNode = fromEl.parentNode;

      if (parentNode) {
        var parentName = parentNode.nodeName.toUpperCase();

        if (parentName === 'OPTGROUP') {
          parentNode = parentNode.parentNode;
          parentName = parentNode && parentNode.nodeName.toUpperCase();
        }

        if (parentName === 'SELECT' && !parentNode.hasAttribute('multiple')) {
          if (fromEl.hasAttribute('selected') && !toEl.selected) {
            // Workaround for MS Edge bug where the 'selected' attribute can only be
            // removed if set to a non-empty value:
            // https://developer.microsoft.com/en-us/microsoft-edge/platform/issues/12087679/
            fromEl.setAttribute('selected', 'selected');
            fromEl.removeAttribute('selected');
          } // We have to reset select element's selectedIndex to -1, otherwise setting
          // fromEl.selected using the syncBooleanAttrProp below has no effect.
          // The correct selectedIndex will be set in the SELECT special handler below.


          parentNode.selectedIndex = -1;
        }
      }

      syncBooleanAttrProp(fromEl, toEl, 'selected');
    },

    /**
     * The "value" attribute is special for the <input> element since it sets
     * the initial value. Changing the "value" attribute without changing the
     * "value" property will have no effect since it is only used to the set the
     * initial value.  Similar for the "checked" attribute, and "disabled".
     */
    INPUT: function INPUT(fromEl, toEl) {
      syncBooleanAttrProp(fromEl, toEl, 'checked');
      syncBooleanAttrProp(fromEl, toEl, 'disabled');

      if (fromEl.value !== toEl.value) {
        fromEl.value = toEl.value;
      }

      if (!toEl.hasAttribute('value')) {
        fromEl.removeAttribute('value');
      }
    },
    TEXTAREA: function TEXTAREA(fromEl, toEl) {
      var newValue = toEl.value;

      if (fromEl.value !== newValue) {
        fromEl.value = newValue;
      }

      var firstChild = fromEl.firstChild;

      if (firstChild) {
        // Needed for IE. Apparently IE sets the placeholder as the
        // node value and vise versa. This ignores an empty update.
        var oldValue = firstChild.nodeValue;

        if (oldValue == newValue || !newValue && oldValue == fromEl.placeholder) {
          return;
        }

        firstChild.nodeValue = newValue;
      }
    },
    SELECT: function SELECT(fromEl, toEl) {
      if (!toEl.hasAttribute('multiple')) {
        var selectedIndex = -1;
        var i = 0; // We have to loop through children of fromEl, not toEl since nodes can be moved
        // from toEl to fromEl directly when morphing.
        // At the time this special handler is invoked, all children have already been morphed
        // and appended to / removed from fromEl, so using fromEl here is safe and correct.

        var curChild = fromEl.firstChild;
        var optgroup;
        var nodeName;

        while (curChild) {
          nodeName = curChild.nodeName && curChild.nodeName.toUpperCase();

          if (nodeName === 'OPTGROUP') {
            optgroup = curChild;
            curChild = optgroup.firstChild;
          } else {
            if (nodeName === 'OPTION') {
              if (curChild.hasAttribute('selected')) {
                selectedIndex = i;
                break;
              }

              i++;
            }

            curChild = curChild.nextSibling;

            if (!curChild && optgroup) {
              curChild = optgroup.nextSibling;
              optgroup = null;
            }
          }
        }

        fromEl.selectedIndex = selectedIndex;
      }
    }
  };
  var ELEMENT_NODE = 1;
  var DOCUMENT_FRAGMENT_NODE$1 = 11;
  var TEXT_NODE = 3;
  var COMMENT_NODE = 8;

  function noop() {}

  function defaultGetNodeKey(node) {
    if (node) {
      return node.getAttribute && node.getAttribute('id') || node.id;
    }
  }

  function morphdomFactory(morphAttrs) {
    return function morphdom(fromNode, toNode, options) {
      if (!options) {
        options = {};
      }

      if (typeof toNode === 'string') {
        if (fromNode.nodeName === '#document' || fromNode.nodeName === 'HTML' || fromNode.nodeName === 'BODY') {
          var toNodeHtml = toNode;
          toNode = doc.createElement('html');
          toNode.innerHTML = toNodeHtml;
        } else {
          toNode = toElement(toNode);
        }
      }

      var getNodeKey = options.getNodeKey || defaultGetNodeKey;
      var onBeforeNodeAdded = options.onBeforeNodeAdded || noop;
      var onNodeAdded = options.onNodeAdded || noop;
      var onBeforeElUpdated = options.onBeforeElUpdated || noop;
      var onElUpdated = options.onElUpdated || noop;
      var onBeforeNodeDiscarded = options.onBeforeNodeDiscarded || noop;
      var onNodeDiscarded = options.onNodeDiscarded || noop;
      var onBeforeElChildrenUpdated = options.onBeforeElChildrenUpdated || noop;
      var childrenOnly = options.childrenOnly === true; // This object is used as a lookup to quickly find all keyed elements in the original DOM tree.

      var fromNodesLookup = Object.create(null);
      var keyedRemovalList = [];

      function addKeyedRemoval(key) {
        keyedRemovalList.push(key);
      }

      function walkDiscardedChildNodes(node, skipKeyedNodes) {
        if (node.nodeType === ELEMENT_NODE) {
          var curChild = node.firstChild;

          while (curChild) {
            var key = undefined;

            if (skipKeyedNodes && (key = getNodeKey(curChild))) {
              // If we are skipping keyed nodes then we add the key
              // to a list so that it can be handled at the very end.
              addKeyedRemoval(key);
            } else {
              // Only report the node as discarded if it is not keyed. We do this because
              // at the end we loop through all keyed elements that were unmatched
              // and then discard them in one final pass.
              onNodeDiscarded(curChild);

              if (curChild.firstChild) {
                walkDiscardedChildNodes(curChild, skipKeyedNodes);
              }
            }

            curChild = curChild.nextSibling;
          }
        }
      }
      /**
       * Removes a DOM node out of the original DOM
       *
       * @param  {Node} node The node to remove
       * @param  {Node} parentNode The nodes parent
       * @param  {Boolean} skipKeyedNodes If true then elements with keys will be skipped and not discarded.
       * @return {undefined}
       */


      function removeNode(node, parentNode, skipKeyedNodes) {
        if (onBeforeNodeDiscarded(node) === false) {
          return;
        }

        if (parentNode) {
          parentNode.removeChild(node);
        }

        onNodeDiscarded(node);
        walkDiscardedChildNodes(node, skipKeyedNodes);
      } // // TreeWalker implementation is no faster, but keeping this around in case this changes in the future
      // function indexTree(root) {
      //     var treeWalker = document.createTreeWalker(
      //         root,
      //         NodeFilter.SHOW_ELEMENT);
      //
      //     var el;
      //     while((el = treeWalker.nextNode())) {
      //         var key = getNodeKey(el);
      //         if (key) {
      //             fromNodesLookup[key] = el;
      //         }
      //     }
      // }
      // // NodeIterator implementation is no faster, but keeping this around in case this changes in the future
      //
      // function indexTree(node) {
      //     var nodeIterator = document.createNodeIterator(node, NodeFilter.SHOW_ELEMENT);
      //     var el;
      //     while((el = nodeIterator.nextNode())) {
      //         var key = getNodeKey(el);
      //         if (key) {
      //             fromNodesLookup[key] = el;
      //         }
      //     }
      // }


      function indexTree(node) {
        if (node.nodeType === ELEMENT_NODE || node.nodeType === DOCUMENT_FRAGMENT_NODE$1) {
          var curChild = node.firstChild;

          while (curChild) {
            var key = getNodeKey(curChild);

            if (key) {
              fromNodesLookup[key] = curChild;
            } // Walk recursively


            indexTree(curChild);
            curChild = curChild.nextSibling;
          }
        }
      }

      indexTree(fromNode);

      function handleNodeAdded(el) {
        onNodeAdded(el);
        var curChild = el.firstChild;

        while (curChild) {
          var nextSibling = curChild.nextSibling;
          var key = getNodeKey(curChild);

          if (key) {
            var unmatchedFromEl = fromNodesLookup[key]; // if we find a duplicate #id node in cache, replace `el` with cache value
            // and morph it to the child node.

            if (unmatchedFromEl && compareNodeNames(curChild, unmatchedFromEl)) {
              curChild.parentNode.replaceChild(unmatchedFromEl, curChild);
              morphEl(unmatchedFromEl, curChild);
            } else {
              handleNodeAdded(curChild);
            }
          } else {
            // recursively call for curChild and it's children to see if we find something in
            // fromNodesLookup
            handleNodeAdded(curChild);
          }

          curChild = nextSibling;
        }
      }

      function cleanupFromEl(fromEl, curFromNodeChild, curFromNodeKey) {
        // We have processed all of the "to nodes". If curFromNodeChild is
        // non-null then we still have some from nodes left over that need
        // to be removed
        while (curFromNodeChild) {
          var fromNextSibling = curFromNodeChild.nextSibling;

          if (curFromNodeKey = getNodeKey(curFromNodeChild)) {
            // Since the node is keyed it might be matched up later so we defer
            // the actual removal to later
            addKeyedRemoval(curFromNodeKey);
          } else {
            // NOTE: we skip nested keyed nodes from being removed since there is
            //       still a chance they will be matched up later
            removeNode(curFromNodeChild, fromEl, true
            /* skip keyed nodes */
            );
          }

          curFromNodeChild = fromNextSibling;
        }
      }

      function morphEl(fromEl, toEl, childrenOnly) {
        var toElKey = getNodeKey(toEl);

        if (toElKey) {
          // If an element with an ID is being morphed then it will be in the final
          // DOM so clear it out of the saved elements collection
          delete fromNodesLookup[toElKey];
        }

        if (!childrenOnly) {
          // optional
          if (onBeforeElUpdated(fromEl, toEl) === false) {
            return;
          } // update attributes on original DOM element first


          morphAttrs(fromEl, toEl); // optional

          onElUpdated(fromEl);

          if (onBeforeElChildrenUpdated(fromEl, toEl) === false) {
            return;
          }
        }

        if (fromEl.nodeName !== 'TEXTAREA') {
          morphChildren(fromEl, toEl);
        } else {
          specialElHandlers.TEXTAREA(fromEl, toEl);
        }
      }

      function morphChildren(fromEl, toEl) {
        var curToNodeChild = toEl.firstChild;
        var curFromNodeChild = fromEl.firstChild;
        var curToNodeKey;
        var curFromNodeKey;
        var fromNextSibling;
        var toNextSibling;
        var matchingFromEl; // walk the children

        outer: while (curToNodeChild) {
          toNextSibling = curToNodeChild.nextSibling;
          curToNodeKey = getNodeKey(curToNodeChild); // walk the fromNode children all the way through

          while (curFromNodeChild) {
            fromNextSibling = curFromNodeChild.nextSibling;

            if (curToNodeChild.isSameNode && curToNodeChild.isSameNode(curFromNodeChild)) {
              curToNodeChild = toNextSibling;
              curFromNodeChild = fromNextSibling;
              continue outer;
            }

            curFromNodeKey = getNodeKey(curFromNodeChild);
            var curFromNodeType = curFromNodeChild.nodeType; // this means if the curFromNodeChild doesnt have a match with the curToNodeChild

            var isCompatible = undefined;

            if (curFromNodeType === curToNodeChild.nodeType) {
              if (curFromNodeType === ELEMENT_NODE) {
                // Both nodes being compared are Element nodes
                if (curToNodeKey) {
                  // The target node has a key so we want to match it up with the correct element
                  // in the original DOM tree
                  if (curToNodeKey !== curFromNodeKey) {
                    // The current element in the original DOM tree does not have a matching key so
                    // let's check our lookup to see if there is a matching element in the original
                    // DOM tree
                    if (matchingFromEl = fromNodesLookup[curToNodeKey]) {
                      if (fromNextSibling === matchingFromEl) {
                        // Special case for single element removals. To avoid removing the original
                        // DOM node out of the tree (since that can break CSS transitions, etc.),
                        // we will instead discard the current node and wait until the next
                        // iteration to properly match up the keyed target element with its matching
                        // element in the original tree
                        isCompatible = false;
                      } else {
                        // We found a matching keyed element somewhere in the original DOM tree.
                        // Let's move the original DOM node into the current position and morph
                        // it.
                        // NOTE: We use insertBefore instead of replaceChild because we want to go through
                        // the `removeNode()` function for the node that is being discarded so that
                        // all lifecycle hooks are correctly invoked
                        fromEl.insertBefore(matchingFromEl, curFromNodeChild); // fromNextSibling = curFromNodeChild.nextSibling;

                        if (curFromNodeKey) {
                          // Since the node is keyed it might be matched up later so we defer
                          // the actual removal to later
                          addKeyedRemoval(curFromNodeKey);
                        } else {
                          // NOTE: we skip nested keyed nodes from being removed since there is
                          //       still a chance they will be matched up later
                          removeNode(curFromNodeChild, fromEl, true
                          /* skip keyed nodes */
                          );
                        }

                        curFromNodeChild = matchingFromEl;
                      }
                    } else {
                      // The nodes are not compatible since the "to" node has a key and there
                      // is no matching keyed node in the source tree
                      isCompatible = false;
                    }
                  }
                } else if (curFromNodeKey) {
                  // The original has a key
                  isCompatible = false;
                }

                isCompatible = isCompatible !== false && compareNodeNames(curFromNodeChild, curToNodeChild);

                if (isCompatible) {
                  // We found compatible DOM elements so transform
                  // the current "from" node to match the current
                  // target DOM node.
                  // MORPH
                  morphEl(curFromNodeChild, curToNodeChild);
                }
              } else if (curFromNodeType === TEXT_NODE || curFromNodeType == COMMENT_NODE) {
                // Both nodes being compared are Text or Comment nodes
                isCompatible = true; // Simply update nodeValue on the original node to
                // change the text value

                if (curFromNodeChild.nodeValue !== curToNodeChild.nodeValue) {
                  curFromNodeChild.nodeValue = curToNodeChild.nodeValue;
                }
              }
            }

            if (isCompatible) {
              // Advance both the "to" child and the "from" child since we found a match
              // Nothing else to do as we already recursively called morphChildren above
              curToNodeChild = toNextSibling;
              curFromNodeChild = fromNextSibling;
              continue outer;
            } // No compatible match so remove the old node from the DOM and continue trying to find a
            // match in the original DOM. However, we only do this if the from node is not keyed
            // since it is possible that a keyed node might match up with a node somewhere else in the
            // target tree and we don't want to discard it just yet since it still might find a
            // home in the final DOM tree. After everything is done we will remove any keyed nodes
            // that didn't find a home


            if (curFromNodeKey) {
              // Since the node is keyed it might be matched up later so we defer
              // the actual removal to later
              addKeyedRemoval(curFromNodeKey);
            } else {
              // NOTE: we skip nested keyed nodes from being removed since there is
              //       still a chance they will be matched up later
              removeNode(curFromNodeChild, fromEl, true
              /* skip keyed nodes */
              );
            }

            curFromNodeChild = fromNextSibling;
          } // END: while(curFromNodeChild) {}
          // If we got this far then we did not find a candidate match for
          // our "to node" and we exhausted all of the children "from"
          // nodes. Therefore, we will just append the current "to" node
          // to the end


          if (curToNodeKey && (matchingFromEl = fromNodesLookup[curToNodeKey]) && compareNodeNames(matchingFromEl, curToNodeChild)) {
            fromEl.appendChild(matchingFromEl); // MORPH

            morphEl(matchingFromEl, curToNodeChild);
          } else {
            var onBeforeNodeAddedResult = onBeforeNodeAdded(curToNodeChild);

            if (onBeforeNodeAddedResult !== false) {
              if (onBeforeNodeAddedResult) {
                curToNodeChild = onBeforeNodeAddedResult;
              }

              if (curToNodeChild.actualize) {
                curToNodeChild = curToNodeChild.actualize(fromEl.ownerDocument || doc);
              }

              fromEl.appendChild(curToNodeChild);
              handleNodeAdded(curToNodeChild);
            }
          }

          curToNodeChild = toNextSibling;
          curFromNodeChild = fromNextSibling;
        }

        cleanupFromEl(fromEl, curFromNodeChild, curFromNodeKey);
        var specialElHandler = specialElHandlers[fromEl.nodeName];

        if (specialElHandler) {
          specialElHandler(fromEl, toEl);
        }
      } // END: morphChildren(...)


      var morphedNode = fromNode;
      var morphedNodeType = morphedNode.nodeType;
      var toNodeType = toNode.nodeType;

      if (!childrenOnly) {
        // Handle the case where we are given two DOM nodes that are not
        // compatible (e.g. <div> --> <span> or <div> --> TEXT)
        if (morphedNodeType === ELEMENT_NODE) {
          if (toNodeType === ELEMENT_NODE) {
            if (!compareNodeNames(fromNode, toNode)) {
              onNodeDiscarded(fromNode);
              morphedNode = moveChildren(fromNode, createElementNS(toNode.nodeName, toNode.namespaceURI));
            }
          } else {
            // Going from an element node to a text node
            morphedNode = toNode;
          }
        } else if (morphedNodeType === TEXT_NODE || morphedNodeType === COMMENT_NODE) {
          // Text or comment node
          if (toNodeType === morphedNodeType) {
            if (morphedNode.nodeValue !== toNode.nodeValue) {
              morphedNode.nodeValue = toNode.nodeValue;
            }

            return morphedNode;
          } else {
            // Text node to something else
            morphedNode = toNode;
          }
        }
      }

      if (morphedNode === toNode) {
        // The "to node" was not compatible with the "from node" so we had to
        // toss out the "from node" and use the "to node"
        onNodeDiscarded(fromNode);
      } else {
        if (toNode.isSameNode && toNode.isSameNode(morphedNode)) {
          return;
        }

        morphEl(morphedNode, toNode, childrenOnly); // We now need to loop over any keyed nodes that might need to be
        // removed. We only do the removal if we know that the keyed node
        // never found a match. When a keyed node is matched up we remove
        // it out of fromNodesLookup and we use fromNodesLookup to determine
        // if a keyed node has been matched up or not

        if (keyedRemovalList) {
          for (var i = 0, len = keyedRemovalList.length; i < len; i++) {
            var elToRemove = fromNodesLookup[keyedRemovalList[i]];

            if (elToRemove) {
              removeNode(elToRemove, elToRemove.parentNode, false);
            }
          }
        }
      }

      if (!childrenOnly && morphedNode !== fromNode && fromNode.parentNode) {
        if (morphedNode.actualize) {
          morphedNode = morphedNode.actualize(fromNode.ownerDocument || doc);
        } // If we had to swap out the from node with a new node because the old
        // node was not compatible with the target node then we need to
        // replace the old DOM node in the original DOM tree. This is only
        // possible if the original DOM node was part of a DOM tree which
        // we know is the case if it has a parent node.


        fromNode.parentNode.replaceChild(morphedNode, fromNode);
      }

      return morphedNode;
    };
  }

  var morphdom = morphdomFactory(morphAttrs);

  var inputTags = {
    INPUT: true,
    TEXTAREA: true,
    SELECT: true
  };
  var mutableTags = {
    INPUT: true,
    TEXTAREA: true,
    OPTION: true
  };
  var textInputTypes = {
    'datetime-local': true,
    'select-multiple': true,
    'select-one': true,
    color: true,
    date: true,
    datetime: true,
    email: true,
    month: true,
    number: true,
    password: true,
    range: true,
    search: true,
    tel: true,
    text: true,
    textarea: true,
    time: true,
    url: true,
    week: true
  };

  //

  var isTextInput = function isTextInput(element) {
    return inputTags[element.tagName] && textInputTypes[element.type];
  }; // Assigns focus to the appropriate element... preferring the explicitly passed selector
  //
  // * selector - a CSS selector for the element that should have focus
  //

  var assignFocus = function assignFocus(selector) {
    var element = selector && selector.nodeType === Node.ELEMENT_NODE ? selector : document.querySelector(selector);
    var focusElement = element || exports.activeElement;
    if (focusElement && focusElement.focus) focusElement.focus();
  }; // Dispatches an event on the passed element
  //
  // * element - the element
  // * name - the name of the event
  // * detail - the event detail
  //

  var dispatch = function dispatch(element, name, detail) {
    if (detail === void 0) {
      detail = {};
    }

    var init = {
      bubbles: true,
      cancelable: true,
      detail: detail
    };
    var evt = new CustomEvent(name, init);
    element.dispatchEvent(evt);
    if (window.jQuery) window.jQuery(element).trigger(name, detail);
  }; // Accepts an xPath query and returns the element found at that position in the DOM
  //

  var xpathToElement = function xpathToElement(xpath) {
    return document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
  }; // Return an array with the class names to be used
  //
  // * names - could be a string or an array of strings for multiple classes.
  //

  var getClassNames = function getClassNames(names) {
    return Array(names).flat();
  }; // Perform operation for either the first or all of the elements returned by CSS selector
  //
  // * operation - the instruction payload from perform
  // * callback - the operation function to run for each element
  //

  var processElements = function processElements(operation, callback) {
    Array.from(operation.selectAll ? operation.element : [operation.element]).forEach(callback);
  };

  var verifyNotMutable = function verifyNotMutable(detail, fromEl, toEl) {
    // Skip nodes that are equal:
    // https://github.com/patrick-steele-idem/morphdom#can-i-make-morphdom-blaze-through-the-dom-tree-even-faster-yes
    if (!mutableTags[fromEl.tagName] && fromEl.isEqualNode(toEl)) return false;
    return true;
  };
  var verifyNotPermanent = function verifyNotPermanent(detail, fromEl, toEl) {
    var permanentAttributeName = detail.permanentAttributeName;
    if (!permanentAttributeName) return true;
    var permanent = fromEl.closest("[" + permanentAttributeName + "]"); // only morph attributes on the active non-permanent text input

    if (!permanent && isTextInput(fromEl) && fromEl === exports.activeElement) {
      var ignore = {
        value: true
      };
      Array.from(toEl.attributes).forEach(function (attribute) {
        if (!ignore[attribute.name]) fromEl.setAttribute(attribute.name, attribute.value);
      });
      return false;
    }

    return !permanent;
  };

  var shouldMorphCallbacks = [verifyNotMutable, verifyNotPermanent];
  var didMorphCallbacks = []; // Indicates whether or not we should morph an element via onBeforeElUpdated callback
  // SEE: https://github.com/patrick-steele-idem/morphdom#morphdomfromnode-tonode-options--node
  //

  var shouldMorph = function shouldMorph(operation) {
    return function (fromEl, toEl) {
      return !shouldMorphCallbacks.map(function (callback) {
        return typeof callback === 'function' ? callback(operation, fromEl, toEl) : true;
      }).includes(false);
    };
  }; // Execute any pluggable functions that modify elements after morphing via onElUpdated callback
  //


  var didMorph = function didMorph(operation) {
    return function (el) {
      didMorphCallbacks.forEach(function (callback) {
        if (typeof callback === 'function') callback(operation, el);
      });
    };
  };

  var DOMOperations = {
    // DOM Mutations
    append: function append(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-append', operation);
        var html = operation.html,
            focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.insertAdjacentHTML('beforeend', html);
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-append', operation);
      });
    },
    graft: function graft(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-graft', operation);
        var parent = operation.parent,
            focusSelector = operation.focusSelector;
        var parentElement = document.querySelector(parent);

        if (!operation.cancel && parentElement) {
          parentElement.appendChild(element);
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-graft', operation);
      });
    },
    innerHtml: function innerHtml(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-inner-html', operation);
        var html = operation.html,
            focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.innerHTML = html;
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-inner-html', operation);
      });
    },
    insertAdjacentHtml: function insertAdjacentHtml(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-insert-adjacent-html', operation);
        var html = operation.html,
            position = operation.position,
            focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.insertAdjacentHTML(position || 'beforeend', html);
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-insert-adjacent-html', operation);
      });
    },
    insertAdjacentText: function insertAdjacentText(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-insert-adjacent-text', operation);
        var text = operation.text,
            position = operation.position,
            focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.insertAdjacentText(position || 'beforeend', text);
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-insert-adjacent-text', operation);
      });
    },
    morph: function morph(operation) {
      processElements(operation, function (element) {
        var html = operation.html;
        var template = document.createElement('template');
        template.innerHTML = String(html).trim();
        operation.content = template.content;
        dispatch(element, 'cable-ready:before-morph', operation);
        var childrenOnly = operation.childrenOnly,
            focusSelector = operation.focusSelector;
        var parent = element.parentElement;
        var ordinal = Array.from(parent.children).indexOf(element);

        if (!operation.cancel) {
          morphdom(element, childrenOnly ? template.content : template.innerHTML, {
            childrenOnly: !!childrenOnly,
            onBeforeElUpdated: shouldMorph(operation),
            onElUpdated: didMorph(operation)
          });
          assignFocus(focusSelector);
        }

        dispatch(parent.children[ordinal], 'cable-ready:after-morph', operation);
      });
    },
    outerHtml: function outerHtml(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-outer-html', operation);
        var html = operation.html,
            focusSelector = operation.focusSelector;
        var parent = element.parentElement;
        var ordinal = Array.from(parent.children).indexOf(element);

        if (!operation.cancel) {
          element.outerHTML = html;
          assignFocus(focusSelector);
        }

        dispatch(parent.children[ordinal], 'cable-ready:after-outer-html', operation);
      });
    },
    prepend: function prepend(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-prepend', operation);
        var html = operation.html,
            focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.insertAdjacentHTML('afterbegin', html);
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-prepend', operation);
      });
    },
    remove: function remove(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-remove', operation);
        var focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.remove();
          assignFocus(focusSelector);
        }

        dispatch(document, 'cable-ready:after-remove', operation);
      });
    },
    replace: function replace(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-replace', operation);
        var html = operation.html,
            focusSelector = operation.focusSelector;
        var parent = element.parentElement;
        var ordinal = Array.from(parent.children).indexOf(element);

        if (!operation.cancel) {
          element.outerHTML = html;
          assignFocus(focusSelector);
        }

        dispatch(parent.children[ordinal], 'cable-ready:after-replace', operation);
      });
    },
    textContent: function textContent(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-text-content', operation);
        var text = operation.text,
            focusSelector = operation.focusSelector;

        if (!operation.cancel) {
          element.textContent = text;
          assignFocus(focusSelector);
        }

        dispatch(element, 'cable-ready:after-text-content', operation);
      });
    },
    // Element Property Mutations
    addCssClass: function addCssClass(operation) {
      processElements(operation, function (element) {
        var _element$classList;

        dispatch(element, 'cable-ready:before-add-css-class', operation);
        var name = operation.name;
        if (!operation.cancel) (_element$classList = element.classList).add.apply(_element$classList, getClassNames(name));
        dispatch(element, 'cable-ready:after-add-css-class', operation);
      });
    },
    removeAttribute: function removeAttribute(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-remove-attribute', operation);
        var name = operation.name;
        if (!operation.cancel) element.removeAttribute(name);
        dispatch(element, 'cable-ready:after-remove-attribute', operation);
      });
    },
    removeCssClass: function removeCssClass(operation) {
      processElements(operation, function (element) {
        var _element$classList2;

        dispatch(element, 'cable-ready:before-remove-css-class', operation);
        var name = operation.name;
        if (!operation.cancel) (_element$classList2 = element.classList).remove.apply(_element$classList2, getClassNames(name));
        dispatch(element, 'cable-ready:after-remove-css-class', operation);
      });
    },
    setAttribute: function setAttribute(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-set-attribute', operation);
        var name = operation.name,
            value = operation.value;
        if (!operation.cancel) element.setAttribute(name, value);
        dispatch(element, 'cable-ready:after-set-attribute', operation);
      });
    },
    setDatasetProperty: function setDatasetProperty(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-set-dataset-property', operation);
        var name = operation.name,
            value = operation.value;
        if (!operation.cancel) element.dataset[name] = value;
        dispatch(element, 'cable-ready:after-set-dataset-property', operation);
      });
    },
    setProperty: function setProperty(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-set-property', operation);
        var name = operation.name,
            value = operation.value;
        if (!operation.cancel && name in element) element[name] = value;
        dispatch(element, 'cable-ready:after-set-property', operation);
      });
    },
    setStyle: function setStyle(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-set-style', operation);
        var name = operation.name,
            value = operation.value;
        if (!operation.cancel) element.style[name] = value;
        dispatch(element, 'cable-ready:after-set-style', operation);
      });
    },
    setStyles: function setStyles(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-set-styles', operation);
        var styles = operation.styles;

        for (var _i = 0, _Object$entries = Object.entries(styles); _i < _Object$entries.length; _i++) {
          var _Object$entries$_i = _Object$entries[_i],
              name = _Object$entries$_i[0],
              value = _Object$entries$_i[1];
          if (!operation.cancel) element.style[name] = value;
        }

        dispatch(element, 'cable-ready:after-set-styles', operation);
      });
    },
    setValue: function setValue(operation) {
      processElements(operation, function (element) {
        dispatch(element, 'cable-ready:before-set-value', operation);
        var value = operation.value;
        if (!operation.cancel) element.value = value;
        dispatch(element, 'cable-ready:after-set-value', operation);
      });
    },
    // DOM Events
    dispatchEvent: function dispatchEvent(operation) {
      processElements(operation, function (element) {
        var name = operation.name,
            detail = operation.detail;
        dispatch(element, name, detail);
      });
    },
    // Browser Manipulations
    clearStorage: function clearStorage(operation) {
      dispatch(document, 'cable-ready:before-clear-storage', operation);
      var type = operation.type;
      var storage = type === 'session' ? sessionStorage : localStorage;
      if (!operation.cancel) storage.clear();
      dispatch(document, 'cable-ready:after-clear-storage', operation);
    },
    go: function go(operation) {
      dispatch(window, 'cable-ready:before-go', operation);
      var delta = operation.delta;
      if (!operation.cancel) history.go(delta);
      dispatch(window, 'cable-ready:after-go', operation);
    },
    pushState: function pushState(operation) {
      dispatch(window, 'cable-ready:before-push-state', operation);
      var state = operation.state,
          title = operation.title,
          url = operation.url;
      if (!operation.cancel) history.pushState(state || {}, title || '', url);
      dispatch(window, 'cable-ready:after-push-state', operation);
    },
    removeStorageItem: function removeStorageItem(operation) {
      dispatch(document, 'cable-ready:before-remove-storage-item', operation);
      var key = operation.key,
          type = operation.type;
      var storage = type === 'session' ? sessionStorage : localStorage;
      if (!operation.cancel) storage.removeItem(key);
      dispatch(document, 'cable-ready:after-remove-storage-item', operation);
    },
    replaceState: function replaceState(operation) {
      dispatch(window, 'cable-ready:before-replace-state', operation);
      var state = operation.state,
          title = operation.title,
          url = operation.url;
      if (!operation.cancel) history.replaceState(state || {}, title || '', url);
      dispatch(window, 'cable-ready:after-replace-state', operation);
    },
    scrollIntoView: function scrollIntoView(operation) {
      var element = operation.element;
      dispatch(element, 'cable-ready:before-scroll-into-view', operation);
      if (!operation.cancel) element.scrollIntoView(operation);
      dispatch(element, 'cable-ready:after-scroll-into-view', operation);
    },
    setCookie: function setCookie(operation) {
      dispatch(document, 'cable-ready:before-set-cookie', operation);
      var cookie = operation.cookie;
      if (!operation.cancel) document.cookie = cookie;
      dispatch(document, 'cable-ready:after-set-cookie', operation);
    },
    setFocus: function setFocus(operation) {
      var element = operation.element;
      dispatch(element, 'cable-ready:before-set-focus', operation);
      if (!operation.cancel) assignFocus(element);
      dispatch(element, 'cable-ready:after-set-focus', operation);
    },
    setStorageItem: function setStorageItem(operation) {
      dispatch(document, 'cable-ready:before-set-storage-item', operation);
      var key = operation.key,
          value = operation.value,
          type = operation.type;
      var storage = type === 'session' ? sessionStorage : localStorage;
      if (!operation.cancel) storage.setItem(key, value);
      dispatch(document, 'cable-ready:after-set-storage-item', operation);
    },
    // Notifications
    consoleLog: function consoleLog(operation) {
      var message = operation.message,
          level = operation.level;
      level && ['warn', 'info', 'error'].includes(level) ? console[level](message) : console.log(message);
    },
    notification: function notification(operation) {
      dispatch(document, 'cable-ready:before-notification', operation);
      var title = operation.title,
          options = operation.options;
      if (!operation.cancel) Notification.requestPermission().then(function (result) {
        operation.permission = result;
        if (result === 'granted') new Notification(title || '', options);
      });
      dispatch(document, 'cable-ready:after-notification', operation);
    },
    playSound: function playSound(operation) {
      dispatch(document, 'cable-ready:before-play-sound', operation);
      var src = operation.src;

      if (!operation.cancel) {
        var canplaythrough = function canplaythrough() {
          document.audio.removeEventListener('canplaythrough', canplaythrough);
          document.audio.play();
        };

        var ended = function ended() {
          document.audio.removeEventListener('ended', canplaythrough);
          dispatch(document, 'cable-ready:after-play-sound', operation);
        };

        document.audio.addEventListener('canplaythrough', canplaythrough);
        document.audio.addEventListener('ended', ended);
        document.audio.src = src;
        document.audio.play();
      } else dispatch(document, 'cable-ready:after-play-sound', operation);
    }
  };

  var perform = function perform(operations, options) {
    if (options === void 0) {
      options = {
        emitMissingElementWarnings: true
      };
    }

    for (var name in operations) {
      if (operations.hasOwnProperty(name)) {
        var entries = operations[name];

        for (var i = 0; i < entries.length; i++) {
          var operation = entries[i];

          try {
            if (operation.selector) {
              operation.element = operation.xpath ? xpathToElement(operation.selector) : document[operation.selectAll ? 'querySelectorAll' : 'querySelector'](operation.selector);
            } else {
              operation.element = document;
            }

            if (operation.element || options.emitMissingElementWarnings) {
              exports.activeElement = document.activeElement;
              DOMOperations[name](operation);
            }
          } catch (e) {
            if (operation.element) {
              console.error("CableReady detected an error in " + name + ": " + e.message + ". If you need to support older browsers make sure you've included the corresponding polyfills. https://docs.stimulusreflex.com/setup#polyfills-for-ie11.");
              console.error(e);
            } else {
              console.log("CableReady " + name + " failed due to missing DOM element for selector: '" + operation.selector + "'");
            }
          }
        }
      }
    }
  };

  var performAsync = function performAsync(operations, options) {
    if (options === void 0) {
      options = {
        emitMissingElementWarnings: true
      };
    }

    return new Promise(function (resolve, reject) {
      try {
        resolve(perform(operations, options));
      } catch (err) {
        reject(err);
      }
    });
  };

  document.addEventListener('DOMContentLoaded', function () {
    if (!document.audio) {
      document.audio = new Audio('data:audio/mpeg;base64,//OExAAAAAAAAAAAAEluZm8AAAAHAAAABAAAASAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPz8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/P39/f39/f39/f39/f39/f39/f39/f39/f3+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/AAAAAAAAAAAAAAAAAAAAAAAAAAAAJAa/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//MUxAAAAANIAAAAAExBTUUzLjk2LjFV//MUxAsAAANIAAAAAFVVVVVVVVVVVVVV//MUxBYAAANIAAAAAFVVVVVVVVVVVVVV//MUxCEAAANIAAAAAFVVVVVVVVVVVVVV');

      var unlockAudio = function unlockAudio() {
        document.body.removeEventListener('click', unlockAudio);
        document.body.removeEventListener('touchstart', unlockAudio);
        document.audio.play().then(function () {})["catch"](function () {});
      };

      document.body.addEventListener('click', unlockAudio);
      document.body.addEventListener('touchstart', unlockAudio);
    }
  });
  var cable_ready = {
    perform: perform,
    performAsync: performAsync,
    DOMOperations: DOMOperations,
    shouldMorphCallbacks: shouldMorphCallbacks,
    didMorphCallbacks: didMorphCallbacks
  };

  exports.default = cable_ready;

})));
//# sourceMappingURL=cable_ready.cjs.umd.js.map
