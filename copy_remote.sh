# Gather parameters
SRC_REPO=$1
DEST_REPO=$2

if [ -z "$SRC_REPO" ]; then
	echo "Welcome."
	echo "What is the source remote repo you'd like to copy from?"
	echo "Please give the complete SSH URL to the remote."
	read SRC_REPO
fi

if [ -z "$DEST_REPO" ]; then
	echo "Welcome."
	echo "What is the destination remote repo you'd like to copy from?"
	echo "Please give the complete SSH URL to the remote."
	read DEST_REPO
fi

LOCAL_FOLDER=./temp-repo

# Do not attempt to clone if the local folder already exists
if [ -f $LOCAL_FOLDER ]
then
    echo "Working folder $LOCAL_FOLDER already exists!"
	exit 1
fi

# Clone the repo with --mirror
# Use --mirror instead of --bare to copy all refs from the source repository
git clone --mirror $SRC_REPO $LOCAL_FOLDER/.git || exit 1

# Navigate into the repo, change settings as appropriate, then push
cd $LOCAL_FOLDER
git remote set-url origin $DEST_REPO
git push --mirror
cd ../
rm -rf $LOCAL_FOLDER