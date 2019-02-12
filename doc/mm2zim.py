#!/usr/bin/env python3

import xml.etree.ElementTree
import sys
import os
import re
import time

db = {}

def fill_db(node, path=None):
    children = node.findall('node')
    for m in children:
        fullpath = (path or [])
        db[m.get('ID')] = fullpath
        fill_db(m, fullpath + [m.get('TEXT')])

def handle_nodes(node, path=None):
    children = node.findall('node')
    for m in children:
        text = " ".join(m.get('TEXT').split())
        escaped = text.translate(str.maketrans('() ', '___'))
        ident=m.get('ID')
        links=[link.get('DESTINATION') for link in m.findall('arrowlink')]
        handle_nodes(m, (path or []) + [{ 'escaped': escaped,
                                          'text':    text,
                                          'created': int(m.get('CREATED')),
                                          'id':      ident,
                                          'links':   links}])
    if not children:
        p = "/".join([x['escaped'] for x in path[:-1]])
        d = p + ".txt"
        os.makedirs(p, exist_ok=True)
        if not os.path.exists(d):
            with open(d, "w") as f:
                f.write ("Content-Type: text/x-zim-wiki\n")
                f.write ("Wiki-Format: zim 0.4\n")
                created=path[-1]['created']
                f.write ("Creation-Date: {time}\n".format(time=time.strftime('%Y-%m-%dT%H:%M:%S+01:00', time.gmtime(created/1000))))
        with open(d, "a") as f:
            f.write ("\n")
            f.write ("* " + path[-1]['text'] + "\n")
            if path[-1]['links']:
                f.write ("Ref: " + ", ".join('[[' + ":".join(db[p]) + ']]' for p in path[-1]['links']) + "\n")

basedir=sys.argv[2]
mm = xml.etree.ElementTree.parse(sys.argv[1]).getroot()
fill_db(mm, [])
handle_nodes(mm, [{ 'escaped': basedir,
                    'text':    basedir,
                    'created': 0,
                    'id':      'root'}])

os.makedirs(basedir, exist_ok=True)
with open(basedir + "/notebook.zim", 'w') as f:
    f.write('[Notebook]\n')
    f.write('version=0.4\n')
    f.write('name={name}\n'.format(name=basedir))
    f.write('interwiki=\n')
    f.write('home=Home\n')
    f.write('icon=\n')
    f.write('document_root=\n')
    f.write('shared=True\n')
    f.write('endofline=unix\n')
    f.write('disable_trash=False\n')
    f.write('profile=\n')
