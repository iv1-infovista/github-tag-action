# github-tag-action

A Github Action to automatically tag master, on merge, base on the date format YYYYMMXXX.

### Usage

```Dockerfile
name: Bump version
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: '0'
    - name: Bump version and push tag
      uses: iv1-infovista/github-tag-action@latest
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        DRY_RUN: true
```

_NOTE: set the fetch-depth for `actions/checkout@v2` to be sure you retrieve all commits to look for an existing commit message._

#### Options

**Environment Variables**

* **GITHUB_TOKEN** ***(required)*** - Required for permission to tag the repo.
* **SOURCE** *(optional)* - Operate on a relative path under $GITHUB_WORKSPACE.
* **DRY_RUN** *(optional)* - Determine the next version without tagging the branch. The workflow can use the outputs `new_tag` and `tag` in subsequent steps. Possible values are ```true``` and ```false``` (default).
* **INITIAL_VERSION** *(optional)* - Set initial version before bump. Default is current year, month, 000.
* **TAG_CONTEXT** *(optional)* - Set the context of the previous tag. Possible values are `repo` (default) or `branch`.
* **VERBOSE** *(optional)* - Print git logs. For some projects these logs may be very large. Possible values are ```true``` (default) and ```false```. 

#### Outputs

* **new_tag** - The value of the newly created tag.
* **tag** - The value of the latest tag after running this action.
* **prev_tag** - The value of the previous tag.

> ***Note:*** This action creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference).

### Taging

**Automatic Bumping:** retrieve the previous tag an increment it by one

> ***Note:*** This action **will not** bump the tag if the `HEAD` commit has already been tagged.

### Workflow

* Add this action to your repo
* Commit some changes
* Either push to master or open a PR
* On push (or merge), the action will:
  * Get latest tag
  * Generate a new tag
  * Pushes tag to github
  * If triggered on your repo's default branch (`master` or `main` if unchanged), the tag version will be a release tag.

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
[anothrNick/github-tag-action](https://github.com/anothrNick/github-tag-action)


### Projects using github-tag-action

A list of projects using github-tag-action for reference.

* another/github-tag-action (uses itself to create tags)

* [anothrNick/json-tree-service](https://github.com/anothrNick/json-tree-service)

  > Access JSON structure with HTTP path parameters as keys/indices to the JSON.
