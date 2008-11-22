case $singleton_sin
when /\.sin$/
  eval(File.read($singleton_sin))
when /\.sina$/
  sin '/' do
    self.instance_eval File.read($singleton_sin)
  end
end