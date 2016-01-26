service "activemq" do
  action [:stop, :disable]
end

# Need to pkill -9 for 11.10 + 5.5.1
`pkill -f apache-activemq`