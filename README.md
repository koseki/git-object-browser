# git-object-browser

Browse git raw objects.


## Installation

    $ gem install git-object-browser

## Usage

To browse .git directory:

    $ git object-browser ./path/to/project
    $ open http://localhost:8080/#/.git

To dump .git directory (dump HTML/JSON/JS app):

    $ git object-browser --dump path/to/dump/dir path/to/project
    $ ${any_http_server} --port 8080 path/to/dump/dir
    $ open http://localhost:8080/#/step1/.git/

To dump .git step by step:

    $ git object-browser --dump path/to/dump/dir --next path/to/project

this command shows .git diff between previous step and current step.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
