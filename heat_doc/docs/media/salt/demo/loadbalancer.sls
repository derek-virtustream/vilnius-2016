nginx:
  pkg:
    - installed
  service.running:
    - enable: True
    - order: last
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf
  require:
    - selinux: httpd_can_network_connect
    - file: /etc/nginx/nginx.conf
    - file: /etc/salt/master.d/peers.conf

salt-master:
  service.running:
    - enable: True
    - watch:
      - file: /etc/salt/master.d/peers.conf
  file.managed:
    - name: /etc/salt/master.d/peers.conf
    - source: salt://demo/files/peers.conf

salt-minion:
  service.running:
    - enable: True
    - watch:
      - file: /etc/salt/minion.d/mine.conf
  file.managed:
    - name: /etc/salt/minion.d/mine.conf
    - source: salt://demo/files/mine.conf

httpd_can_network_connect:
  selinux.boolean:
    - value: True
    - persist: True

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://demo/templates/nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - watch:
      - file: /etc/salt/master.d/peers.conf
      - file: /etc/salt/minion.d/mine.conf
