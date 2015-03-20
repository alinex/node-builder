Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.0.18 (2015-03-20)
-------------------------------------------------
- Fixed repository change.

Version 1.0.17 (2015-03-19)
-------------------------------------------------
- Fixed some problems with the new spawn.

Version 1.0.16 (2015-03-19)
-------------------------------------------------
- Fix new config paths.

Version 1.0.15 (2015-03-19)
-------------------------------------------------
- Allow to change configsearch path.
- Display tables as documented in html (<pre>).
- Fixed title of fork me image in documentation.
- Better error output on invalid json file.

Version 1.0.14 (2015-03-16)
-------------------------------------------------
- Fixed update command.

Version 1.0.13 (2015-03-16)
-------------------------------------------------
- Switch registry if specific publishConfig entry is set.
- Add compile task to publish commands.

Version 1.0.12 (2015-03-11)
-------------------------------------------------
- Fixed EEXIST error which comes some times in compile.
- Added --force and --try switches and changed order to work each directory after the other.
- Stop task if outdated modules found.

Version 1.0.11 (2015-03-10)
-------------------------------------------------
- Remove --prune from push.
- Update documentation structure.
- Added verbose info for mocha .only checking.

Version 1.0.10 (2015-03-06)
-------------------------------------------------
- Remove .only test to let publish work again.
- Fixed missing callback in new method.
- Fix order of commands to run doc after publish.
- Replace fs with alinex-fs in publish.
- Add test for .only tests before publish.
- Updated documentation.

Version 1.0.9 (2015-03-06)
-------------------------------------------------
- Fixed problem with module load after clean.
- Added document generation to publish.
- Fixed bug in automatic added commands.

Version 1.0.8 (2015-03-06)
-------------------------------------------------
- Typo fixed.
- Add clean and test tasks as dependent to publish.
- Be more parallel in document creation.
- Also copy images from source folders to documentation folder.
- Fixed flag attributes which prevent directory parameters to be detected.
- Removed dir output without verbose mode.

Version 1.0.7 (2015-03-05)
-------------------------------------------------
- Fixed call to npmbin to find command line tools needed.
- Return error if npmfind could not find manpage conversion.
- Fixed package.json
- Updated documentation style.
- Also create test/mocha directory for mocha tests.
- Updated man page.
- Updated created package.json to use builder as well.

Version 1.0.3 (2015-02-27)
-------------------------------------------------
- Fixed some bugs preventing doc task to publish.
- Added create task and list outdated in update task.
- Added new node version to travis.

Version 1.0.0 (2015-02-26)
-------------------------------------------------
- Fixed bug in test task which didn't find coffeelint or mocha.
- Converted most of the other tasks.
- Reworked changes task.
- Updated pull and push task to be open for more repositories.
- Moved task into special subdir.
- Updated compile task to work parallel.
- Rename package to name `builder`.
- Merge pull request #2 from jbnicolai/update-chalk-v1.0.0
- Updates chalk to 1.0.0.
- Ignore mkdir error if the directory is was already created.
- Make CLI argument parsing more strict.
- Added example output for publish command.

Version 0.4.6 (2014-12-30)
-------------------------------------------------
- Fix typo in package.json.
- Moved chai to dev dependencies.
- Only publish docs if specified as option.
- Added changes command.
- Small bugfix in creating docs for non alinex packages.
- Fixed internal links in documentation.
- Changed created script calls to support newer make.
- Updated to use newest make version in created files.
- Fixed create task which was completely buggy since last rewrite.
- Updated packages to allow mocha 2.0.
- Removed empty version entries.
- Small fix in command line parsing.
- Support compiling markdown into man pages.
- Fixed package.json version check.
- Fixed package.json version notation.
- Submodule tough-cookie working again.

Version 0.4.5 (2014-10-08)
-------------------------------------------------
- Fixed npm package to include /var/src folder.

Version 0.4.3 (2014-09-27)
-------------------------------------------------
- Replace colors with chalk submodule.

Version 0.4.0 (2014-09-27)
-------------------------------------------------
- Updated submodule replace to version 0.3.x.

Version 0.3.2 (2014-09-17)
-------------------------------------------------
- Fixed small bug preventing alinex layout to be used.

Version 0.3.1 (2014-09-11)
-------------------------------------------------
- Upgrade to debug 2.0
- Fixed bug in install target which broke after doing the first task.
- Automatically run dependent commands.

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
