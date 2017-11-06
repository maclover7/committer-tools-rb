# committer-tools-rb

Working on [committer-tools](https://github.com/maclover7/committer-tools) for right now because Promises are givin me a huge headache :)

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
  - make sure final commit message ok
- What this does not automates:
  - pushing the actual commit

Try it out by using:

```
GH_TOKEN=mytoken123 committer-tools land
```

### License

Copyright (c) 2017+ Jon Moss under the MIT License.
