Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

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
