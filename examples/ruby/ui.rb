require 'ycp'
YCP::Ui::init("qt")
include YCP::Ui

t = HBox( Label("Welcome to Ruby!"), PushButton("Push me") )
# You can also use downcase, as the symbols are aliased
#t = hbox( label("Welcome to Ruby!"), pushbutton("Push me") )

puts "#{t.to_s} #{t.class}"

# how should this work?
# ui.OpenDialog(t)
# ui.UserInput()

p YCP::call_ycp_function( "UI", "OpenDialog", t )
p YCP::call_ycp_function( "UI", "UserInput" )
