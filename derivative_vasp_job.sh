#!/bin/sh

echo "I will copy INCAR / POTCAR / KPOINTS + CONTCAT --> POSCAR, into the directory you now supply:"

read newd

mkdir "${newd}"

cp -a INCAR POTCAR KPOINTS "${newd}"
cp -a CONTCAR "${newd}/POSCAR"

echo "OK; done - now get in there and correct your errors :^)"

cd ${newd}
