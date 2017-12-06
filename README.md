# committer-tools-rb

Useful CLI utilities for Node.js collaborators. Writing in Ruby while I
try and figure out what's going on with Promises in the JS version of
this :)

### Installation

```bash
gem install committer-tools
```

### Usage

In order to use `committer-tools`, you need to create a `.ctconfig` file
in your home directory, with the following contents:

```json
{
  "token": "A GitHub token with user:email scope"
}
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

Make sure you have a PR ID ready; as an example, the ID for
`https://github.com/nodejs/node#14998` would be `nodejs/node#14998`.

Once you have a PR ready to land, you can then land it by running:

```
committer-tools land
```

### License

Copyright (c) 2017+ Jon Moss under the MIT License.
