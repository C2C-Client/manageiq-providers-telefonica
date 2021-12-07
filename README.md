# manageiq-providers-telefonica

[![Gem Version](https://badge.fury.io/rb/manageiq-providers-telefonica.svg)](http://badge.fury.io/rb/manageiq-providers-telefonica)
[![Build Status](https://travis-ci.org/ManageIQ/manageiq-providers-telefonica.svg?branch=master)](https://travis-ci.org/ManageIQ/manageiq-providers-telefonica)
[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq-providers-telefonica?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Translate](https://img.shields.io/badge/translate-zanata-blue.svg)](https://translate.zanata.org/zanata/project/view/manageiq-providers-telefonica)

ManageIQ plugin for the Telefonica provider.

## Development

See the section on pluggable providers in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup)

For quick local setup run `bin/setup`, which will clone the core ManageIQ repository under the *spec* directory and setup necessary config files. If you have already cloned it, you can run `bin/update` to bring the core ManageIQ code up to date.

### VCR cassettes re-recording

You will need testing Telefonica environment(s) and `telefonica_environments.yml` file with credentials in format like:
```yml
---
- test_env_1:
    ip: 11.22.33.44
    password: long_password_1
    user: admin_1
- test_env_2:
    ip: 11.22.33.55
    password: long_password_2
    user: admin_2
```

Then you can run `bundle exec rake vcr:rerecord` and following will happen:
* Current VCR cassettes files will be deleted
* Credentials from `telefonica_environments.yml` file will be injected into spec files
* Specs needed for re-recording of VCR cassettes will be run. During this step manageiq will call Telefonica APIs at specified endpoints
* Credentials present in spec files and VCR cassettes will be changed to dummy data so tests can run from VCR cassettes

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
