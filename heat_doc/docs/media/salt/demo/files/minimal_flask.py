from flask import Flask
from flask import request
import socket

app = Flask(__name__)
REQUESTS = 0

@app.route('/')
def hello_world():
    global REQUESTS
    REQUESTS += 1
    out = """<html>
    <head><title>Hello OpenStack Heat</title></head>
    <body>
    <h1>Hello OpenStack Heat</h1>
    <p>This is request #%d to hit this server.</p>
    <p>This server is host %s.</p>
    </body>
    </html>""" % (REQUESTS, socket.gethostname())
    return out



if __name__ == '__main__':
    app.run(host="0.0.0.0", port=9876)
