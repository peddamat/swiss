# This Mercurial hook updates the staging server when the client pushes a commit.
#
# - Sumanth Peddamatham <peddamat@gmail.com>
#

PWD=`pwd`
PROJECT_DIR=`basename ${PWD}`
RELOAD_SCRIPT=/Users/me/Coding/Projects-ROR/redmine-1.2-tgdev/vendor/plugins/redmine_project_initializer/scripts/reload_database_hook.rb

reload_database()
{
   ${RELOAD_SCRIPT} ${PROJECT_DIR}
}

update_staging_directory()
{
  rm -Rf ${DEPLOY_DIR}
  hg update
  hg clone . ${DEPLOY_DIR} -q
  mv ${DEPLOY_DIR}/src/* ${DEPLOY_DIR}

  reload_database
}

update_staging_directory

