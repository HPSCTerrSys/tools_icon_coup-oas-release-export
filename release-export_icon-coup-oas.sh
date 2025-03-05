#!bin/bash

# set version by hand
#iconversion="icon-2024.07" #take from icon tag
coupversion="2.0.1"

# Clone icon-coup repository
git clone -b oas-coup https://icg4geo.icg.kfa-juelich.de/ModelSystems/icon_master.git icon_github
cd icon_github
iconversion=$(git describe --abbrev=0 --tags)
# make sure that iconversion matches
read -p "Is ${iconversion} the correct ICON version? " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
#
#tagname=${iconversion}_coup-oasis3-mct_cplv${coupversion}
tagname=${iconversion}_coup-oas_cplv${coupversion}
git tag ${tagname}
git push origin ${tagname}

# change remote for submodules
sed -i "s# ../..# https://gitlab.dkrz.de#g" .gitmodules
git submodule sync --recursive

# get submodules
submodulename=("ecrad" "cdi" "mtime" "fortran-support") # 2024.07
for ii in "${submodulename[@]}"; do
  git submodule update --init -- externals/$ii
done

# 
git restore .gitmodules

# Remove submodule alternative would be a merge, but history is not stored anyhow
for isub in "${submodulename[@]}"; do
  rm -rf externals/${isub}/.git
  mv externals/${isub} externals/${isub}_tmp
  git rm --cached externals/${isub}/
  mv externals/${isub}_tmp externals/${isub}
  git add -f externals/${isub}/
done

# clean up all remaining submodules
git rm --cached $(git submodule | awk '{ print $2 }')
git rm .gitmodules

# new branch with clean history
#branchname=${tagname%_*} # cut before last _
#branchname=${iconversion}-public_${tagname#*_}
branchname=${iconversion}-public_coup-oas
git checkout --orphan ${branchname}
git commit -m "Release export from tag ${tagname}"

# update github
#hpscgit_tagname=${branchname}${tagname#$iconversion}
hpscgit_tagname=${branchname}_${tagname##*_}
git tag ${hpscgit_tagname}
git remote add hpscgit git@github.com:HPSCTerrSys/icon-model_coup-oas.git
git push -u hpscgit ${branchname}
git push -u hpscgit ${hpscgit_tagname}

# clean up
cd .. 
rm -rf icon_github
