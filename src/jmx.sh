# Check that the JMX agent requires SSL for RMI registry
curl -vvv -k https://127.0.0.1:9990
openssl s_client -showcerts -connect 127.0.0.1:9990

