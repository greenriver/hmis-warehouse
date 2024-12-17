# ADR 003: Warehouse Frontend Modernization

## Status

- Current Status: Proposed
- Date of last update: 2024-12-17
- Decision-makers: Engineering team

## Context

The warehouse currently uses Bootstrap 4.x as the primary component library and jQuery/Stimulus for client-side behaviors. This presents several challenges and opportunities for modernization:

**Current Challenges:**
- Bootstrap 4.x has reached end-of-life and is no longer maintained
- Codebase contains significant repeated code due to limited component reuse
- Interface is somewhat inconsistent due to lack of re-usable components
- Large number of forms and CRUD interfaces need ongoing support
- Accessibility requirements need to be addressed systematically
- Currently using several approaches to asset management (sprockets and jsbundling)
- CSS and javascript lacks consistent architecture

**Technical Environment:**
- Need to maintain and improve large number of existing interfaces in the warehouse
- Rails 8 recommends using 'Hotwire,' a suite of tools including Turbo Drive/Frames for responsive page loads, Websockets/ActionCable for real-time updates, and Stimulus as a JavaScript framework.
- HMIS interfaces are implemented React/MUI on the HMIS
- Complete re-implementation of rails interfaces in React would be cost-prohibitive
- View components are not currently utilized but represent a potential solution to improve modularity

## Decision

Proposed multi-tiered approach to frontend modernization:

1. **Upgrade to Bootstrap 5** as the primary UI component library
   - Bootstrap 5 is currently supported and maintained
   - Leverages team familiarity with Bootstrap ecosystem
   - Compatible with many existing Bootstrap 4.x patterns
   - Migration will involve auditing and updating existing templates and custom styles, particularly where Bootstrap 4.x-specific classes are used.

2. **Implement View Components** for common UI patterns
   - Create reusable components for menus, tables, other common UI elements
   - Focus on high-value, frequently used components first
   - Standardize and document these components as preferred patterns
   - Gradually adopt these components during feature development
   - Create generic wrappers for Bootstrap components

3. **Standardize on Stimulus for JS Custom Behaviors**
   - Continue to standardize on Stimulus for organizing component-specific JavaScript
   - Ensure stimulus is upgraded to the most recent major version
   - Integrate Stimulus with Turbo and view components
   - Continue using jQuery where it makes sense (DOM manipulation, AJAX, Bootstrap integration)

4. **CSS Architecture Strategy**
   - Leverage Bootstrap 5 utilities as the primary styling mechanism
   - Use View Component namespacing for CSS scoping

5. **Asset Management**
   - Complete migration from sprockets to jsbundling (or rails 8 default propshaft)

## Consequences

**Positive:**
   - Lower migration effort from Bootstrap 4.x to 5.x compared to switching frameworks
   - Team already familiar with Bootstrap patterns and concepts
   - Clear upgrade path documented by Bootstrap team
   - Can reuse existing components and patterns with minimal changes
   - Strong focus on backward compatibility in Bootstrap 5
   - Stimulus provides more structured approach to JavaScript
   - Better alignment with Rails ecosystem and future direction
   - Improved testability through Stimulus controllers

**Negative:**
   - Less flexible than utility-first approaches such as tailwind
   - Continued dependency on Bootstrap
   - Initial development time to upgrade bootstrap
   - Initial development time to create view components

## Alternatives Considered

1. **Complete React Migration**
   - Rejected due to prohibitive cost and time requirements
   - Would provide most modern solution but impractical

2. **Stick with Bootstrap 4.x** Purchase Extended Support
   - Rejected due to maintenance risks
   - Additional cost without solving underlying issues

3. **CSS Methodologies**
   - BEM: Rejected due to verbose syntax and complexity
   - CSS Modules: Rejected due to added build complexity
   - Tailwind: Rejected due to migration cost from Bootstrap
   - CSS-in-JS: Rejected due to poor fit with Rails ecosystem

## Additional Info

Implementation Notes:
- Migration strategy will require an initial push to upgrade to bootstrap 5. Then gradual development and adoption of view components.
- Need to create comprehensive component library documentation
- Establish testing standards for view components and Stimulus controllers
- Adjust or establish storybook-like style guide for the warehouse

References:
- [Bootstrap 4.x EOL announcement](https://getbootstrap.com/docs/4.6/end-of-life/)
- [Hotwire](https://hotwired.dev/)
- [Rails View Components guide](https://viewcomponent.org/)
