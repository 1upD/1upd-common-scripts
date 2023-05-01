# This script was something I wrote roughly a year ago (last modified on 2022-04-14)
# to test different merge scenarios to see which merge strategies were the cleanest
# for me.
#
# I am committing this file nearly a year later in case it is useful for demonstration
# in the future.
setup_test_dir ()
{
  git checkout $ORIGINAL_BRANCH
  git reset HEAD --hard
  echo "Removing $DIRECTORY...."
  rm -r $DIRECTORY || echo "Couldn't remove $DIRECTORY"
  echo "Creating $DIRECTORY..."
  mkdir $DIRECTORY
  echo "Copying merge_strategy.sh..."
  cp ./merge_strategy.sh $DIRECTORY/
}

reset () 
{
  git checkout $ORIGINAL_BRANCH
  git reset HEAD --hard
  git branch -D dev-test
  git branch -D main-test
  git branch -D release-test
  git branch -D bugfix-test
  git branch -D hotfix-test

  git checkout -b main-test
  git add $DIRECTORY/*
  git commit -m "Initial commit of merge strategy test"

  git checkout -b dev-test
  git checkout dev-test
}

replace_string ()
{
  find=$1
  replace=$2

  echo "Replacing ${find} with ${replace}..."
  find $DIRECTORY -type f -exec sed -i "s/${find}/${replace}/g" {} +
}

merge()
{
  source=$1
  dest=$2
  squash=$3

  if [ $squash == 0 ] ; then
    echo "Returning to $dest..."
    git checkout $dest
    echo "Merge from $source to $dest..."
    git merge $source --no-ff
	git mergetool
  else
    echo "Returning to $dest..."
    git checkout $dest
    echo "Merging $source..."
    git merge $source --squash
	
	git mergetool
	
    git add $DIRECTORY/*
    git commit -m "Merge from $source to $dest"      
  fi
}

# The first scenario is a gitflow release promotion.
# Make some change A on the dev branch. Then cut a release branch.
# Then, on the dev branch, make another change B.
# Merge release to main, then backmerge main to dev. 
# RESULT: Squashing creates a conflict between B and A,
#  while a merge commit merges cleanly.
scenario_1 ()
{
  squash=$1

  # Check out dev-test
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string git scm
  
  # Commit A
  echo "Committing A..."
  git add $DIRECTORY/*
  git commit -m "A"
  
  # Cut release-test
  echo "Cutting release branch..."
  git checkout -b release-test
  
  # Check out dev-test
  echo "Returning to dev..."
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string scm hg

  # Commit B
  echo "Committing B..."
  git add $DIRECTORY/*
  git commit -m B

  # Merge release-test to main-test
  merge release-test main-test $squash
  
  # Merge main-test to dev-test
  merge main-test dev-test $squash
}

scenario_1_merge ()
{
  scenario_1 0
}

scenario_1_squash ()
{
  scenario_1 1
}

# The scecond scenario is a bugfix into a release branch.
# The first steps are the same as scenario 1:
# Make some change A on the dev branch. Then cut a release branch.
# Then, on the dev branch, make another change B.
# Then, for scenario 2, check out the release branch. Cut a bugfix branch.
# Make a third change C.
# Merge to release.
# Then backmerge to dev.
# RESULT: Both merge strategies produce the same conflict as there is a genuine conflict in the file.
scenario_2 ()
{
  squash=$1

  # Check out dev-test
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string git scm
  
  # Commit A
  echo "Committing A..."
  git add $DIRECTORY/*
  git commit -m "A"
  
  # Cut release-test
  echo "Cutting release branch..."
  git checkout -b release-test
  
  # Check out dev-test
  echo "Returning to dev..."
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string scm hg

  # Commit B
  echo "Committing B..."
  git add $DIRECTORY/*
  git commit -m B
  
  # Cut bugfix-test
  echo "Cutting bugfix branch..."
  git checkout release-test
  git checkout -b bugfix-test
  
  # Make change to lines X in file Y
  replace_string scm svn
  
  # Commit C
  echo "Committing C..."
  git add $DIRECTORY/*
  git commit -m C

  # Merge bugfix-test to release-test
  merge bugfix-test release-test $squash
  
  # Merge release-test to dev-test
  merge release-test dev-test $squash
}

scenario_2_merge ()
{
  scenario_2 0
}

scenario_2_squash ()
{
  scenario_2 1
}

# Variation on second scenario: What if the changes are independent?
# RESULT: Squash merging and merge commits produce the same conflicts.
#  There is no difference.
scenario_2a ()
{
  squash=$1

  # Check out dev-test
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string git scm
  
  # Commit A
  echo "Committing A..."
  git add $DIRECTORY/*
  git commit -m "A"
  
  # Cut release-test
  echo "Cutting release branch..."
  git checkout -b release-test
  
  # Check out dev-test
  echo "Returning to dev..."
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string scm hg

  # Commit B
  echo "Committing B..."
  git add $DIRECTORY/*
  git commit -m B
  
  # Cut bugfix-test
  echo "Cutting bugfix branch..."
  git checkout release-test
  git checkout -b bugfix-test
  
  # Make change to lines Z in file Y
  replace_string echo print
  
  # Commit C
  echo "Committing C..."
  git add $DIRECTORY/*
  git commit -m C

  # Merge bugfix-test to release-test
  merge bugfix-test release-test $squash
  
  # Merge release-test to dev-test
  merge release-test dev-test $squash
}

scenario_2_merge ()
{
  scenario_2 0
}

scenario_2_squash ()
{
  scenario_2 1
}

# The third scenario is a gitflow hotfix.
# Start with all of the steps from scenario 1, up until the merge to dev-test.
# Next, cut a branch from main-test called hotfix-test.
# Make an independent change to hotfix test.
# Merge hotfix-test to main-test.
# Merge main-test to dev-test
# RESULT: Both merge strategies result in conflicts, but not the same conflicts.
#  With a merge commit, the hotfix merge to release goes smoothly, and then
#  the merge from main back to dev runs into conflicts but they can be automatically
#  resolved with Kdiff3. (This usually means it's obvious from history which changes to keep)
#  The same conflict happens with the squash merge strategy, but my merge tool (kdiff3)
#  could not determine which lines are appropriate. This is probably because the two merge 
#  parents don't share the history of Commit A. It's difficult to manually solve this merge.
scenario_3 ()
{
  squash=$1

  # Check out dev-test
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string git scm
  
  # Commit A
  echo "Committing A..."
  git add $DIRECTORY/*
  git commit -m "A"
  
  # Cut release-test
  echo "Cutting release branch..."
  git checkout -b release-test
  
  # Check out dev-test
  echo "Returning to dev..."
  git checkout dev-test

  # Make changes to lines X in file Y
  replace_string scm hg

  # Commit B
  echo "Committing B..."
  git add $DIRECTORY/*
  git commit -m B

  # Merge release-test to main-test
  merge release-test main-test $squash
  
  git checkout main-test
  git checkout -b hotfix-test
  
  # Make change to lines Z in file Y
  replace_string echo print
  
  # Commit C
  echo "Committing C..."
  git add $DIRECTORY/*
  git commit -m C 
  
  # Merge hotfix-test to main-test
  merge hotfix-test main-test $squash
  
  # Merge main-test to dev-test
  merge main-test dev-test $squash
}

git checkout main
export ORIGINAL_BRANCH=main
export DIRECTORY=./tmp
setup_test_dir
reset
scenario_3 1