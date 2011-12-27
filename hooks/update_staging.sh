# This Mercurial hook updates the staging server when the client pushes a commit.
#
# - Sumanth Peddamatham <peddamat@gmail.com>
#

PWD=`pwd`
PROJECT_DIR=`basename ${PWD}`

stage_project()
{
  cd /Users/me/Coding/Projects-ROR/swiss/ 
  ./swiss stage ${PROJECT_DIR}
}

stage_project

