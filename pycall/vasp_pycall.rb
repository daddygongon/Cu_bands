#+begin_src ruby
require 'pycall/import'
include PyCall::Import

pyimport :sys
pyimport 'numpy', as: :np
pyfrom 'pymatgen.io.vasp.outputs', import: :Vasprun

class Dos
  attr_reader :e_f, :energy, :t, :s, :p, :d, :sp
  def initialize(dir)
    @dir = dir
    get_dos
  end

  def get_dos
    dosrun = Vasprun.(File.join(@dir,"vasprun.xml"))
    @e_f = dosrun.efermi
    e_object = (dosrun.tdos.energies - @e_f)
    @energy = PyCall::List.(e_object).to_a
    @t = PyCall::List.(dosrun.tdos.densities.to_a[0][1]).to_a

    spd_dos = dosrun.complete_dos.get_spd_dos()
    @s = get_spd_list(spd_dos, 0)
    @p = get_spd_list(spd_dos, 1)
    @d = get_spd_list(spd_dos, 2)
    @sp = []
    @energy.size.times { |i| @sp << @s[i]+@p[i] }
  end

  def get_spd_list(spd_dos, i)
    spd_d = spd_dos.to_a[i][1].densities
    PyCall::List.(spd_d.to_a[0][1]).to_a
  end
end
class Band
  attr_reader :e_bands, :p_bands, :spd_ratio, :bands_energy, :n_bands
  def initialize(dir)
    @e_bands, @p_bands = get_bands(dir)
    @n_bands = @e_bands.size
    mk_spd_ratio
    mk_bands_energy
  end
  def get_bands(dir)
    run = Vasprun.(File.join(dir,"vasprun.xml"),
                   parse_projected_eigen: true)
    bands = run.get_band_structure(File.join(dir,"KPOINTS"),
                                 line_mode: true,
                                 efermi: $e_f)
    e_bands = PyCall::List.(bands.bands.to_a[0][1]).to_a
    p arg1 = PyCall::Dict.({'Cu': PyCall::Tuple.(["s", "p", "d"])})
    p_bands = bands.get_projections_on_elements_and_orbitals(arg1)
    return [e_bands, p_bands]
  end
  def mk_spd_ratio
    @spd_ratio = []
    @n_bands.times do |i|
      band_array = PyCall::Dict.(@p_bands).to_a[0][1][i].to_a
      @spd_ratio << band_array.inject([]) do |all, ele|
        s = ele.to_h['Cu']['s']
        p = ele.to_h['Cu']['p']
        d = ele.to_h['Cu']['d']
        all << [s,p,d]
      end
    end
  end
  def mk_bands_energy
    @bands_energy = []
    @n_bands.times do |i|
      @bands_energy <<  PyCall::List.(@e_bands[i]).to_a
    end
  end
end
class Xtics
  attr_reader :xtics, :adjust_x
  def initialize(band_str)
    @band_str = band_str
    @adjust_x = x_adjust((0..240-1).to_a)
    @xtics = mk_xtics
  end
  def x_adjust(data)
    adjusted = []
    x = -0.5
    #BAND_STR
    data.each_with_index do |data, i|
      n = i/40
      step = @band_str[n][2]
      x += step
      adjusted << x
    end
    return adjusted
  end
  def mk_xtics
    string = '( '
    x_v = 0.0
    @band_str.each_with_index do |params, i|
      p step = params[2]
      if i == 0
        string << "\"#{params[1]}\" 0.0, "
      elsif i < 6
        string << "\"#{params[1]}\" #{x_v-step}, "
      else
        string << "\"#{params[1]}\" #{x_v-0.5}"
      end
      x_v += 40*step
    end
    return string + ' )'
  end
end
module Gnuplot
  extend self
  def mk_dos_plot_data(xys)
    yy = xys[0]
    lists = []
    xys[1..-1].each do |xx|
      vals = xx[0]
      title = xx[1]
      lw = xx[2] || 2
      rgb = xx[3] || '#000000'
      lists << [vals, yy, w: :l, lw: lw, lc_rgb: rgb, title: title]
    end
    return lists
  end
  def mk_band_plot_data(x, y, rgbs, plot_data, e_f=0.0)
    (x.size-1).times do |i|
      xx = [x[i],x[i+1]]
      yy = [y[i]-e_f,y[i+1]-e_f]
      rgb = rgbs[i]
      plot_data << [xx, yy, w: :l, lw: 2, lc_rgb: rgb, notitle: '']
    end
  end
  def set_rgbs(spds, sp=true)
    rgbs = []
    spds.each do |ele|
      s,p,d = ele
      total = s**2+p**2+d**2
      if total.to_f >= 0.00000001
        if sp
          r = sprintf("%02x",((s**2+p**2)/total)*255.to_i)
          g = sprintf("%02x",0.to_i)
        else
          r = sprintf("%02x",(s**2/total)*255.to_i)
          g = sprintf("%02x",(p**2/total)*255.to_i)
        end
        b = sprintf("%02x",(d**2/total)*255.to_i)
        rgb = '#'+r+g+b
        rgbs << rgb
      else
        rgbs << '#000000'
      end
    end
    return rgbs
  end
end

dir = ARGV[0] || "../vasp_results"
dos = Dos.new(File.join(dir,'dos_calc'))
xys = [dos.energy,
       [dos.t, 'total', 1, '#000000'],
              [dos.s, 's', 2, '#ff0000'],
              [dos.p, 'p', 2, '#00ff00'],
       # [dos.sp, 's+p', 2, '#ff0000'],
       [dos.d, 'd', 2, '#0000ff']]
dos_plot_data = Gnuplot::mk_dos_plot_data(xys)

BAND_STR = [ # L -> G -> X -> K -> G
            [0, '{/Symbol G}', 0.5],    # G[0,0,0]
            [40,'X', 0.25],              # X[1/2,0,0]
            [80,'W', Math.sqrt(2.0)/4.0],# W[1/2,1/4,0]
            [120, 'L', Math.sqrt(3.0)/4.0], # L[1/4,1/4,1/4]
            [160, '{/Symbol G}', Math.sqrt(18.0)/8.0], # G[0,0,0]
            [200, 'K', Math.sqrt(2.0)/8.0],# K[3/8,3/8,0]
            [240, 'X', 1.0], # X[4/8,4/8,0]
           ]
xtics = Xtics.new(BAND_STR)
x_tics_str = xtics.xtics
ax = xtics.adjust_x
range = ax[-1]

bands = Band.new(File.join(dir,'band_calc'))
bands_energy = bands.bands_energy
spd_ratio = bands.spd_ratio

band_plot_data = []
bands.n_bands.times do |i|
  rgbs = Gnuplot.set_rgbs(spd_ratio[i], false)
  yy = bands_energy[i]
  Gnuplot.mk_band_plot_data(ax, yy, rgbs, band_plot_data, dos.e_f)
end

# multiplot in gnuplot
require 'numo/gnuplot'
Numo.gnuplot do
  set grid: 'ytics lt 2'
  set terminal: "aqua enhanced font 'Verdana,18'"
  set lmargin: 0
  set rmargin: 0
  set tmargin: 0
  set bmargin: 0
  set yrange: '[-10:10]'
  set multiplot: 'title "Band diagram of Cu"'
# dos gnuplot
  set size: '0.3, 0.8'
  set origin: '0.6, 0.1'
  set xrange: '[0:7]'
  set xlabel: 'Density of states'
  unset ytics: ''
  unset xtics: ''
  plot *dos_plot_data
# band gnuplot
  set grid: 'xtics lt 1'
  set size: '0.5, 0.8'
  set origin: '0.1, 0.1'
  set xrange: "[0:#{range}]"
  set ytics: '5'
  set xtics: x_tics_str
  set ylabel: "'{/Verdana-Italic E-E}_F [eV]'"
  set ylabel_offset: "2, 0"
  plot *band_plot_data
  unset multiplot: ''
end

#+end_src


