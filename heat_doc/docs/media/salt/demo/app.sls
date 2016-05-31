app:
  require:
    - pkg: python-flask
    - file: /opt/minimal_flask.py
    - file: /etc/systemd/system/demo.service

# Here is what it looks like to install RPMs directly, if you are curious.
python-flask:
  pkg.installed:
    - sources:
        - python-babel: salt://demo/rpms/python-babel-1.3-6.el7.noarch.rpm
        - python-backports-ssl_match_hostname: salt://demo/rpms/python-backports-ssl_match_hostname-3.4.0.2-4.el7.noarch.rpm
        - python-flask: salt://demo/rpms/python-flask-0.10.1-4.el7.noarch.rpm
        - python-itsdangerous: salt://demo/rpms/python-itsdangerous-0.23-2.el7.noarch.rpm
        - python-jinja2: salt://demo/rpms/python-jinja2-2.7.2-2.el7.noarch.rpm
        - python-setuptools: salt://demo/rpms/python-setuptools-0.9.8-4.el7.noarch.rpm
        - python-werkzeug: salt://demo/rpms/python-werkzeug-0.9.1-2.el7.noarch.rpm
        - pytz: salt://demo/rpms/pytz-2012d-5.el7.noarch.rpm
        - tzdata: salt://demo/rpms/tzdata-2016d-1.el7.noarch.rpm

/opt/minimal_flask.py:
  file.managed:
    - name: /opt/minimal_flask.py
    - source: salt://demo/files/minimal_flask.py
  require:
    - pkg: python-flask

salt-minion:
  service.running:
    - enable: True
    - watch:
      - file: /etc/salt/minion.d/mine.conf
  file.managed:
    - name: /etc/salt/minion.d/mine.conf
    - source: salt://demo/files/mine.conf

/etc/salt/minion.d/mine.conf:
  file.managed:
    - name: /etc/salt/minion.d/mine.conf
    - source: salt://demo/files/mine.conf

demo_service:
  file.managed:
    - name: /etc/systemd/system/demo.service
    - source: salt://demo/files/demo.service
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: demo_service
  require:
    - file: /opt/minimal_flask.py
    - pkg: python-flask

sync-grains:
  module.run:
    - name: saltutil.sync_grains
    - refresh: True

demo:
  service.running:
    - enable: True
    - order: last
    - watch:
      - module: demo_service
      - pkg: python-flask
      - file: /opt/minimal_flask.py
  require:
    - file: /opt/minimal_flask.py
    - pkg: python-flask
    - file: /etc/systemd/system/demo.service
