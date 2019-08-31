#!/bin/bash -e

git describe --tags --always > .version
echo "path: ${PWD} version: $(cat .version)"



if [ "$1" == "" ]; then
    REF=$(git log -1 --pretty=%B)
    echo "Last commit subject: ${REF}"
else
    REF="$@"
    echo "Manual commit subject: ${REF}"
fi


major=$(cut -f1 -d. .version)
minor=$(cut -f2 -d. .version)
patch=$(cut -f3 -d. .version | cut -f1 -d-)
rm .version
oldversion="${major}.${minor}.${patch}"
case "${REF}" in
    bugfix:*|bug:*|fix:*|automatic-patch:*)
        patch=$((patch+1))
        ;;
    feature:*|feat:*)
        patch=0
        minor=$((minor+1))
        ;;
    major:*)
        patch=0
        minor=0
        major=$((major+1))
        ;;
esac
newversion="${major}.${minor}.${patch}"

echo "starting script..."
env | grep TRAVIS
gimme -l
gimme 1.12.9
# install a more recent Go than apt-get can supply
#curl https://dl.google.com/go/go1.12.9.linux-amd64.tar.gz -o go.tar.gz
#sudo tar -xvzf go.tar.gz -C /usr/local/
go version
go env

. /home/travis/.gimme/envs/*.env
#export GOROOT=/usr/local/go
#export PATH="$PATH:${GOROOT}/bin"

echo "installing ghr"
go get -v github.com/tcnksm/ghr
echo "ghr install reported $?"

if [ "${oldversion}" == "${newversion}" ]; then
    echo "version not updated: old: ${oldversion} new: ${newversion}"
    exit 0
fi

echo "new version to be created: old: ${oldversion} new: ${newversion}"

# update version number before upload to supermarket
mkdir tmpdir
mercuryversion=$(grep "mercury\['package'\]\['version'\] =" attributes/mercury.rb | cut -f6 -d\')
echo "${mercuryversion}" > tmpdir/mercury.version
echo "executing ghr"
~/gopath/bin/ghr -soft -t ${GITHUB_TOKEN} -u sbp-cookbooks -r mercury -c ${TRAVIS_COMMIT} -n "Mercury Cookbook v${newversion}" ${newversion} ./tmpdir
echo "ghr reported $?"

sed -e "s/version          '.*'/version          '${newversion}'/" -i metadata.rb
cat metadata.rb

# upload to supermarket
echo "${SUPERMARKET_PEM}" | tr _ "\n" > ~/mercury.pem
chmod 600 ~/mercury.pem
knife supermarket share -u rdoorn -s https://api.opscode.com/organizations/rdoorn -o /home/travis/build/sbp-cookbooks -k ~/mercury.pem mercury -V


# update wrapper cookbook
echo "${GITLAB_DEPLOY_KEY}" | tr _ "\n" > ~/gitlab.pem
chmod 600 ~/gitlab.pem
#echo -e "Host *\nStrictHostKeyChecking no\n" > ~/.ssh/config
export GIT_SSH_COMMAND="ssh -i ~/gitlab.pem -F /dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes" 
git clone ssh://git@sbp.gitlab.schubergphilis.com:2228/SBP-Cookbooks/sbp_mercury_wrapper.git
cd sbp_mercury_wrapper

wrapperversion=$(grep ^version metadata.rb| cut -f2 -d\')
wrappermajmin=$(echo ${wrapperversion} | cut -f1-2 -d.)
wrapperpatch=$(echo ${wrapperversion} | cut -f3 -d.)
wrapperpatch=$((wrapperpatch+1))
wrappernewversion="${wrappermajmin}.${wrapperpatch}"

sed -e "s/depends 'mercury', '= .*'/depends 'mercury', '= ${mercuryversion}'/" -e "s/version          '.*'/version          '${wrappernewversion}'/" -i metadata.rb
git add metadata.rb
git commit -m 'automatic-patch: updating version of mercury cookbook"
git push
