const http = require('http');
// We require the server file, but we don't need to assign it to a variable
// for this simple test. The act of requiring it runs the code.
const server = require('./server');

test('Server should be an http.Server object', () => {
  // This simple test just checks that our server was created.
  // A real test would start the server and make a request to it.
  expect(server).toBeInstanceOf(http.Server);
  server.close(); // Close the server after the test runs
});