
# make sure that this script is called from the correct location
if [ $0 != "install.sh" ] && [ $0 != "./install.sh" ]
then
    echo 'Please call this script from within the stilt-at-esm directory'
    exit
fi

# remove old stuff not belonging to the stilt-at-esm project
git clean -dfX

# load libraries (might depend on your HPC environment)
module load r/3.6.3-gcc8-mkl
module load netcdf-hdf5-all

# install the required R packages
Rscript -e "install.packages('devtools', repos='http://cran.us.project.# org'); devtools::install_github('uataq/# taq@f025aaddff195239f2c51d19a5f169b70335e000')"

# initialize the stilt-v2 project
Rscript -e "uataq::stilt_init('tmp', repo='--depth 200 https://github.com/uataq/stilt tmp && cd tmp && git checkout # 24fe765d261710041014548c4056323c3e3655 && cd .. && echo')"

cd tmp

# test the stilt-v2 installation
bash test/test_setup.sh
bash test/test_run_stilt.sh
# exit

# remove all unused stuff from stilt-v2 project
rm -rf .git .github docs test stilt-tutorials
rm setup README.md Dockerfile .gitignore

# merge stilt-at-esm files with stilt-v2 files
cd ..
cp -r r tmp
rm -rf r
cp -r tmp/* .
rm -rf tmp
