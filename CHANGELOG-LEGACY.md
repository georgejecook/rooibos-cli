## 4.0.0 - add version checking

### Added

 - new install command, for installing the framework directly into a project

### Changed

 - the default command is now `-r` `--run`, this is a breaking change, hence the major bounce.
 - the command is now rooibos-cli, not rooibosC

## 3.1.0 - add version checking

### Added 

 - checks the version of the rooibosDist.brs, and the rooibos-preprocessor used match
 
## 3.0.9 - reintroduces legacy support

### Added

  - legacy unit testing support is reintroduced. Any projects that adhere to the roku unit testing library pre-annotation syntax, will automatically run.
    @only and @ignore is supported for test suites, and test cases.

### Changed

### Deprecated

### Removed

### Fixed

  - adds ignored test info, so that we can get that back in the log report


## 3.0.8 - out of beta - yay!

### Added

  - loads runtime config from a rooibosC generated function which
    - enables fail fast mode
    - enables show only failures mode.

### Changed

### Deprecated

### Removed

### Fixed

  - crash when any function calls asString on an aa that has mocked functions
  - race crash as reported here https://github.com/georgejecook/rooibos/issues/53

## 3.0.7-beta

### Added

### Changed

### Deprecated

### Removed

### Fixed

 - minor issue with coverage support
 
## 3.0.6-beta

### Added

### Changed

### Deprecated

### Removed

### Fixed

 - resolves issue where many lines were missing from the expected lines array

## 3.0.5-beta

### Added
  - support for else if's in coverage

### Changed

### Deprecated

### Removed

### Fixed

 - added glob-all to dependencies

## 3.0.3-beta - package publishing woes

## 3.0.2-beta - package publishing woes

## 3.0.1-beta

### Added

### Changed


### Deprecated

### Removed

### Fixed

 - problem that stopped code coverage working from gulp builds


## 3.0.0-beta

### Added

 - code coverage

### Changed

 - API - now create a config object, and pass that in from js use
 - command line args

### Deprecated

### Removed

### Fixed

 - issues with params parsing - now much more resilient

## 2.1.1

### Added

### Changed

### Deprecated

### Removed

### Fixed

 - runtime error due to bad naming of RuntimeConfig vs RunTimeConfig on Linux operating systems.

## 2.1.0

### Added

### Changed

 - Use debug instead of console.log
 - Separates index exports and CLI, exposing RooibosProcessor, so we can process test files inside of other js/ts tool-chains (like gulp) for non cli test processing

### Deprecated

### Removed

### Fixed

