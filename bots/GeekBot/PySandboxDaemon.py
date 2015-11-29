#!/usr/bin/env python3

# import BaseHTTPServer
# import SimpleHTTPServer
from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver
import threading
import os
import subprocess

class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
	"""Handle requests in a separate thread."""
	daemon_threads = True

PATH = os.environ['PATH']
username = os.getlogin()
PATH = ':'.join(filter(lambda p: username not in p, PATH.split(':'))) # filter out virtualenv
def python(code):
	pypy = subprocess.Popen(['pypy-sandbox'], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
			stderr=subprocess.PIPE, env={'PATH': PATH}, universal_newlines=True, preexec_fn=os.setpgrp)
	try:
		stdout, stderr = pypy.communicate(code, 5)
	except subprocess.TimeoutExpired:
		os.killpg(pypy.pid, signal.SIGKILL)
		return 'timed out after 5 seconds'
	errlines = stderr.split('\n')
	if len(errlines) > 3:
		for i in range(1, len(errlines)):
			line = errlines[-i] # iterate backwards
			if line:
				return line[:250]
	else:
		for line in stdout.split('\n'):
			if line.startswith('>>>> '):
				while line[:5] in ['>>>> ', '.... ']:
					line = line[5:]
				return line[:250]

class MyHandler(BaseHTTPRequestHandler):
	def do_POST(self):
		if self.path.endswith('py'):
			self.send_response(200)
			self.send_header("Content-type", "text/plain")
			self.end_headers()
			content_len = int(self.headers.get('content-length', 0))
			content = self.rfile.read(content_len).decode("utf-8")
			# print(content)
			self.wfile.write(bytes(python(content), "utf-8"))

SERVER_PORT = 1234

if __name__ == '__main__':
	print("Running on port {}".format(SERVER_PORT))
	httpd = ThreadedHTTPServer(('', SERVER_PORT), MyHandler)
	httpd.serve_forever()
