# git-plain

Dump all git objects to plain text files.


## Installation

    $ gem install git-plain

## Usage

Execute 'git plain' in your working directory.

    $ cd working-dir
    $ git plain

creates:

- .git/plain/index
- .git/plain/objects/...

All objects is now readable. Then, you can do this.

    $ cd .git/
    $ git init

Commit all git objects to the .git/.git repository to see how the git repository works.


## Todo 

- Extract packed objects.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
