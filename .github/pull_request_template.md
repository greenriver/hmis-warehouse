## _Merging this PR_
- use the squash-merge strategy for PRs targeting a release-X branch
- use a merge-commit or rebase strategy for PRs targeting the stable branch

## Description
[//]: # (Summarize changes and include links related issue. List any new dependencies)

## Type of change
[//]: # (e.g., Bug fix, New feature, Code clean-up, Dependency update)

## Checklist before requesting review
[//]: # (Remove any items that are not applicable)
- [ ] I have performed a self-review of my code
- [ ] I have run the code that is being changed under ideal conditions, and it doesn't fail
- [ ] If adding a new endpoint / exposing data in a new way, I have:
  - [ ] ensured the API can't leak data from other data sources
  - [ ] ensured this does not introduce N+1s
  - [ ] ensured permissions and visibility checks are performed in the right places
- [ ] I have updated the documentation (or not applicable)
- [ ] I have added spec tests (or not applicable)
- [ ] I have provided testing instructions in this PR or the related issue (or not applicable)
