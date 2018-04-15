#!/bin/sh 
set -e

which jq > /dev/null || (echo "jq not present" && exit 1)
which curl > /dev/null || (echo "curl not present" && exit 1)

LOCAL_TAGS=$(git tag)
set -x
SYMFONY_TAGS=$(curl https://api.github.com/repos/symfony/symfony-standard/tags?page=${PAGE:=1} | jq -r '.[].name')
set +x
#SYMFONY_TAGS="v3.2.3"
STARTING_DIR=$(PWD)

for TAG in $SYMFONY_TAGS; do
	echo "Processing tag: $TAG"
	rm -rf build
	if git rev-list $TAG.. >/dev/null 2>&1
	then
		echo "Tag $TAG already exists!"
	else
		git clone . build
		cd build
		git checkout --orphan worker-$TAG
		git rm --cached -r .
		
		REQUIRES=$(curl https://api.github.com/repos/symfony/symfony-standard/contents/composer.json\?ref\=$TAG | jq -r '.content' | base64 --decode | jq .require)
		
		{
			cat ../template.json;
			echo $REQUIRES;
			echo '}';
		} | jq --indent 4 '.' > composer.json

		git add composer.json
		git commit -m "Import symfony/standard-edition@$TAG"

		git tag $TAG
		
		git push origin --tags
		cd $STARTING_DIR
	fi
done
