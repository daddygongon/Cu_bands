#+begin_src ruby
require 'numo/gnuplot'
# an example of gradient line color plot, the original from
# http://gnuplot-surprising.blogspot.com/2011/09/gradient-colored-curve-in-gnuplot0.html
def f(x)
  return Math.exp(-0.33*x)*Math.sin(5.0*Math::PI*x)   #The function to be plotted
end
n=100   #divide the whole curve into n segments

plot_data = []
range = 10
#Plot the n segments of the curve
n.times do |i|
  #  i<=x*n/range && x*n/range<(i+1.5) ?f(x):1/0 \
  x = [(i-0.5)/n*range,i.to_f/n*range,(i+0.5)/n*range]
  y = [f(x[0]),f(x[1]),f(x[2])]
  plot_data << [x, y, w: :l, lw: 2, lc: :palette, cb: i, notitle: '']
end

Numo.gnuplot do
  set term: 'png'
  set output: "gradient_colored_curve1.png"
#  set samples: 300 #must be large enough for each segment have at least 2 samples
  set palette: 'rgbformulae 30,13,10'    #rainbow palette
  set cbrange: "[0:#{n}]"
  set xrange: "[0:#{range}]"
  unset colorbox: '' #The colorbox will not plotted
  plot *plot_data
end

#+end_src
