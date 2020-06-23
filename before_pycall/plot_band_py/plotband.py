from pymatgen.io.vasp.outputs import Vasprun
from pymatgen.electronic_structure.plotter import BSPlotter

vaspout = Vasprun("./band_calc/vasprun.xml")
bandstr = vaspout.get_band_structure(line_mode=True)
plt = BSPlotter(bandstr).get_plot(ylim=[-12,10])
plt.savefig("band.pdf")
