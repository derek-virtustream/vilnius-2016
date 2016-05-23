app:
  require:
    - pkg: python-flask
    - file: /opt/minimal_flask.py
    - file: /etc/systemd/system/demo.service

python-flask:
  pkg.installed:
    - sources:
        - python_flask: salt://demo/files/python-flask....rpm

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
