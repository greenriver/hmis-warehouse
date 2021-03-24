## ClientAccessControl README

This driver provides mechanisms to control access to client pages.  There may eventually be multiple mechanisms, but the initial arbiter of access looks at the following items:

### For Searching
1. Data sources directly assigned to the user
2. Data sources that are visible in the window
3. Clients with releases of information that are pertinent to the user
4. Clients with enrollments at projects the user has access to through assigned entities

### For Viewing
1. Data sources directly assigned to the user
2. Data sources that are visible in the window, if these are visible without a release
3. Clients with releases of information that are pertinent to the user
4. Clients with enrollments at projects the user has access to through assigned entities
