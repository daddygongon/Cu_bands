#!/usr/bin/env python
# -*- coding=utf-8 -*-

import sys
import numpy as np

import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib.gridspec import GridSpec

# from pymatgen.io.vaspio.vasp_output import Vasprun
from pymatgen.io.vasp.outputs import Vasprun
from pymatgen.electronic_structure.plotter import BSDOSPlotter, BSPlotterProjected
from pymatgen.electronic_structure.core import Spin, OrbitalType

vasprun = Vasprun('./band_calc/vasprun.xml', parse_projected_eigen=True)
band_structure = vasprun.get_band_structure('./band_calc/KPOINTS') #, line_mode=True)
band_structure_plot = BSPlotterProjected(band_structure)
plot = band_structure_plot.get_elt_projected_plots_color()
plot.show()


