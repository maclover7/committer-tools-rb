# committer-tools-rb

Useful CLI utilities for Node.js collaborators. Writing in Ruby while I
try and figure out what's going on with Promises in the JS version of
this :)

### Installation

```bash
gem install committer-tools
```

### Usage

##### `committer-tools ci`

- What this automates
  - get pr id
  - get pr from github api
  - match pr repo to ci.nodejs.org job
  - create a new ci job for pr
- What this does not automate
  - making sure the changes are `CERTIFY_SAFE`-ok

Try it out by using:

```
GH_TOKEN=mytoken123 JENKINS_TOKEN=mytoken123 committer-tools ci
```

##### `committer-tools land`

- What this automates:
  - get pr id
  - get pr from github api
  - put together metadata for commit
  - do a few checks, make sure ok to land
  - pauses, lets you squash, make any edits necessary
  - add metadata to commit message
  - one final round of commit message validation
- What this does not automates:
  - pushing the actual commit

Try it out by using:

```
GH_TOKEN=mytoken123 committer-tools land
```

### License

Copyright (c) 2017+ Jon Moss under the MIT License.
