# committer-tools-rb

Useful CLI utilities for Node.js collaborators. Writing in Ruby while I
try and figure out what's going on with Promises in the JS version of
this :)

### Installation

```bash
gem install committer-tools
```

### Usage

##### `committer-tools land`

- What this automates:
  - get pr id
  - get pr from github api
  - put together metadata for commit
  - do a few checks, make sure ok to land
  - add metadata to commit message
  - make sure final commit message ok
- What this does not automates:
  - pushing the actual commit

Try it out by using:

```
GH_TOKEN=mytoken123 committer-tools land
```

### License

Copyright (c) 2017+ Jon Moss under the MIT License.
