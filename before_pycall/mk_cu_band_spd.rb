require 'scanf'

BAND_STR = [ # L -> G -> X -> K -> G
            [0, '{/Symbol G}', 0.5],    # G[0,0,0]
            [40,'X', 0.25],              # X[1/2,0,0]
            [80,'W', Math.sqrt(2.0)/4.0],# W[1/2,1/4,0]
            [120, 'L', Math.sqrt(3.0)/4.0], # L[1/4,1/4,1/4]
            [160, '{/Symbol G}', Math.sqrt(18.0)/8.0], # G[0,0,0]
            [200, 'K', Math.sqrt(2.0)/8.0],# K[3/8,3/8,0]
            [240, 'X', 1.0], # X[4/8,4/8,0]
  ]

def get_ke_data(lines)
  data=[]
  m = lines[0].match(/\[\[\s+(.+)\]/)
  data << m[1].scanf("%f %f")
  lines.each do |line|
    if m = line.match(/\[\s+(.+)\]\]/)
      data << m[1].scanf("%f %f")
    end
  end
  return data
end

def check_block(lines)
  lines.each_with_index do |line,i|
    if line.size>100
      p [i, line.size]
    end
  end
end

def divide_blocks(lines)
  data = []
  k_es=[]
  colors = []
  lines.each_with_index do |line,i|
    if line.size>100
      p k_es.size
      colors << line
      data << get_ke_data(k_es)
      k_es = []
    else
      k_es << line
    end
  end
  return data,colors
end

def get_rgba(line)
  rgba = []
  line.split(')').each do |ele|
    begin
      m = ele.match(/\((.+)/)
      rgba << m[1].scanf("%f, %f, %f, %f")
    rescue => e
      (ele == "]\n")? next : (p e)
    end
  end
  return rgba
end

def to_rgb(rgb)
  conv = "#"
  sp = rgb[0]+rgb[1]
  d  = rgb[2]
  str = (sp*255).to_i.to_s(16)
  if str.length==1
    conv += '0'+str
  else
    conv += str
  end
  conv += '00'
  str = (d*255).to_i.to_s(16)
  if str.length==1
    conv += '0'+str
  else
    conv += str
  end
    return conv
end

def mk_plot_data(xy, rgbs, plot_data = [])
  n = xy.size-1
  n.times do |i|
    #  i<=x*n/range && x*n/range<(i+1.5) ?f(x):1/0 \
    x = [xy[i][0],xy[i+1][0]]
    y = [xy[i][1],xy[i+1][1]]
    rgb = to_rgb(rgbs[i])
    plot_data << [x, y, w: :l, lw: 2, lc_rgb: rgb, notitle: '']
  end
  return 0
end

def adjust_data_x(data)
  x = -0.5
  #BAND_STR
  data.each_with_index do |data, i|
    n = i/40
    step = BAND_STR[n][2]
    x += step
    data[0] = x
  end
end
require 'numo/gnuplot'
lines = File.readlines('cu_data.txt')

check_block(lines)
data, colors = divide_blocks(lines)
rgba_s = colors.inject([]){|all, color| all << get_rgba(color)}

#n = data[0].size-1
plot_data = []
data.each_with_index do |data,i|
  adjust_data_x(data)
  mk_plot_data(data, rgba_s[i], plot_data)
end
#def mk_plot_data
x_tics_str = '('
x_v = 0.0
BAND_STR.each_with_index do |params, i|
  p step = params[2]
  if i == 0
    x_tics_str << "\"#{params[1]}\" 0.0, "
  elsif i < 6 
    x_tics_str << "\"#{params[1]}\" #{x_v-step}, "
  else
    x_tics_str << "\"#{params[1]}\" #{x_v-0.5}"
#    x_tics_str << "\"#{params[1]}\" 89.74691494688162-0.5"
  end
  p x_v += 40*step
end
x_tics_str << ')'
#  return x_tics_str
#end


p range = data[0][-1][0]
Numo.gnuplot do
#  set term: 'png'
#  set output: "gradient_colored_curve1.png"
#  set samples: 300 #must be large enough for each segment have at least 2 samples
#  set palette: 'rgbformulae 30,13,10'    #rainbow palette
#  set cbrange: "[0:#{n}]"
  set grid: 'xtics lt 1'
  set xrange: "[0:#{range}]"
  set yrange: "[-10:20]"
  set xtics: x_tics_str
  unset colorbox: '' #The colorbox will not plotted
  plot *plot_data
end


