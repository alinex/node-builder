Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 0.3.0 (2014-08-15)
-------------------------------------------------
- Fixed bug in test task and added examples.
- Added install task.
- Restructured all tasks to use new yargs option parsing.
- Finished yargs integration with pull command.
- Start restructuring options parsing.
- Merge branch 'master' of https://github.com/alinex/node-make
- Upgraded to new debug version.

Version 0.2.10 (2014-08-08)
-------------------------------------------------
- Upgraded debug module version.
- More contrast for instance variables in alinex style.
- Again fix for the document link optimization.
- Fixed link optimization for alinex modules.
- Updated documentation.

Version 0.2.9 (2014-07-19)
-------------------------------------------------
- Changed alinex document style.
- Fixed bug which broke anchor links in doc.
- Fixed execute rights to open browser.
- Removed incorrect version change.
- Added information for version 0.2.9

Version 0.2.8 (2014-07-18)
-------------------------------------------------
- Support script changes for specific doc styles like alinex.
- Upgraded istanbul package to version 0.3.
- Optimized changelog.

Version 0.2.7 (2014-07-10)
-------------------------------------------------
- Added debug messages to all tasks.
- Use english language in status call to correctly detect if something has changed.
- Changed gitignore template to be more specific.
- Remove adding of coveralls into created package.json.
- Fixed typo error in console output.

Version 0.2.6 (2014-05-12)
-------------------------------------------------
- Fixed bug in finding binaries.
- Fixed bug in doc to allow overwrting file.
- Replaced own tools (using fs-extra) with alinex-fs.
- Fixed layout problem in alinex-style.
- Fixed typo in documentation: github link text.

Version 0.2.5 (2014-04-25)
-------------------------------------------------
- Optimize accessibility of fork label.
- Add a "Fork me on GitHub" label with link.
- Fix bug in regex for html link correction.
- Support local links in GitHub and docker output to work.
- Added print style without menu for the alinex documentation.

Version 0.2.4 (2014-04-23)
-------------------------------------------------
- Fix coveralls to use correct path.
- Added keywords.
- Made keywords an array like specified for package.json.
- Change to use alinex-make for tests in newly created modules.

Version 0.2.3 (2014-04-18)
-------------------------------------------------
- Added coveralls support to test task.

Version 0.2.2 (2014-04-18)
-------------------------------------------------
- Removed mocha, coffee, chai... in create task because included in alinex-make.
- Make test task use internal mocha and istanbul.
- Move mocha tests in correct directory. Updated documentation to show the optional dir parameter.
- Remove output from second mocha run for istanbul.
- Add alinex-make as build tool on create.
- Added some documentation to the tools.findbin() method.

Version 0.2.1 (2014-04-17)
-------------------------------------------------
- Integrated coffee script compilation into code. Optimized uglify to work also if installed in higher module.
- Removed commander object in favor of combined command object.

Version 0.2.0 (2014-04-17)
-------------------------------------------------
- Make most tasks to allow optional directory parameter, use current as default.
- Optimized the compile task to run on current directory per default.
- Integrated --uglify support for compile of coffee files.
- Added link to the alinex documentation.
- Add compile task which will run coffee script compiler.

Version 0.1.1 (2014-04-15)
-------------------------------------------------
- Small documentation fixes.
- Make commit message option standard conform using -m
- Use uglify-js to compress lib code.
- Changes the alinex layout.
- Extend ignore files for new filestructure.
- Use gitignore and npmignore from this package as template.
- Move the docstyle to the new filestructure position and document it.
- Added support for doc-publish scripts.
- Added support for individual styles in doc pages.
- Also push and pull git repositories without an package.json file.
- Fix writing copyright name in create task.
- Fixed whitespace in badge urls.
- Add the date to the version changelog.
- Run install before running tests.
- Fixed browser call in testTask.
- Adding travis ci to auto creation mode for public repositories in create task.
- Fixed coffescript syntax error in create task.
- Add interactive mode to create task.
- Added --browser option to open local coverage report in test task.
- Try to push to coveralls.
- Add support for coverage report using istanbul in test task.
- Fixed response message of test task.
- Automatically install before running tests.
- Removed node_modules/.../src deletion in cleanTask because buggy.

Version 0.1.0
-------------------------------------------------
- Added --dist and --auto flag implementation to clean task.
- CI tests only on node >= 0.10.
- Added travis contineous integration.
- Added -c as shortcut for commit in publish task.
- Added link to changelog in version tags.
- Added pull task to update from git origin. 
- Fixed up all tasks to be more responsive.
- Added new push task which will only push to origin and renamed old one to publish.
- Make username in create task changeable by parameter.
- Initial buildTask.
- Added example tests.
- Added possibility to run tests defined in package.json.
- Added task clean for cleanups. Added task test with coffee script lint test.
- Fixed the changelog numbering.
- Fixed bug in changelog creation.
- Added --browser flag to document creation, to open the index afterwards. Fixed console output while using --watch in doc task.
- Fixed changelog format in make push.

Version 0.0.3
-------------------------------------------------
- Bug fixes in push with setting correct version.
- Added doc task to create documentation and push it to github.
- Extract error handler in extra module alinex-error.
- Fix git log read for changelog addition.

Version 0.0.2
-------------------------------------------------
- Added information for version 0.0.2
- Added push task to create new versions.
- Also create the source directory on create task.

Version 0.0.1
-------------------------------------------------
- Added command for creating new packages
- Initial commit
