require 'yast'
ui = YaST::Module.new("UI")
YaST::Ui::init("qt")
include YaST::Ui

t = HBox( Label("Welcome to Ruby!"), PushButton("Push me") )

puts "#{t.to_s} #{t.class}"

ui.OpenDialog(t)
ui.UserInput()

# You can also use downcase, as the symbols are aliased
t = hbox( label("Welcome to Ruby!"), pushbutton("Push me") )

puts "#{t.to_s} #{t.class}"

ui.OpenDialog(t)
ui.UserInput()


exit