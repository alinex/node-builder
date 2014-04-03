Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 0.1.0
-------------------------------------------------
- Added --dist and --auto flag implementation to clean task.
- Removed coverage integration.
- Test coverage integration.
- Test coverage integration.
- CI tests only on node >= 0.10.
- Added travis contineous integration.
- Added travis contineous integration.
- Added -c as shortcut for commit in publish task.
- Added link to changelog in version tags.
- Added pull task to update from git origin. Fixed up all other tasks to be more responsive.
- Added new push task which will only push to origin and renamed old one to publish.
- Make username in create task changeable by parameter.
- Initial buildTask.
- Added example tests.
- Added possibility to run tests defined in package.json.
- Added task clean for cleanups. Added task test with coffee script lint test.
- Merge branch 'master' of https://github.com/alinex/node-make
- Fixed the changelog numbering.
- Fixed  bug in changelog creation.
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
