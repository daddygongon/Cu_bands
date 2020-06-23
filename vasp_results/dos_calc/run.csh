#!/bin/csh
#$ -cwd
#$ -S /bin/sh -V
#$ -pe vasp 8
#$ -N test
#$ -q all.q@asura7

mpirun -np 8 /usr/local/vasp/vasp.4.6.28/src/vasp_100_size_build0114          
