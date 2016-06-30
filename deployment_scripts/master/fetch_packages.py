#!/usr/bin/env python
import hashlib, os, sys, urllib2, yaml

def md5(fname):
  hash_md5 = hashlib.md5()
  with open(fname, "rb") as f:
    for chunk in iter(lambda: f.read(4096), b""):
      hash_md5.update(chunk)
  return hash_md5.hexdigest()

def check_file(repo, file_name, md5sum):
  file_path = 'repositories/' + repo + '/' + file_name
  if os.path.isfile(file_path):
    file_chk = md5(file_path)
    if not file_chk == md5sum:
      print 'Failed to fetch file: %s (checksum fail)' % file_name
      sys.exit(1)
  else:
    print 'Failed to fetch file: %s' % file_name
    sys.exit(1)

def fetch_file(repo, file_name, url, md5sum):
  file_chk = ''
  file_path = 'repositories/' + repo + '/' + file_name
  if os.path.isfile(file_path):
    file_chk = md5(file_path)
    if not file_chk == md5sum:
      print '        File: "' + file_name + '" checksum failed'
      if file_chk == 'd41d8cd98f00b204e9800998ecf8427e':
        print '  Looks like file is empty'
      else:
        print 'Expected md5: ' + md5sum
        print '     Got md5: ' + file_chk
      print '  trying to re-fetch it'
  if not ( os.path.isfile(file_path) and file_chk == md5sum ):
    try:
      u = urllib2.urlopen(url, timeout=3)
      meta = u.info()
      f = open(file_path, 'wb')
      file_size = int(meta.getheaders("Content-Length")[0])
      print " Downloading: %s Bytes: %s" % (file_name, file_size)
      file_size_dl = 0
      block_sz = 8192
      while True:
        buffer = u.read(block_sz)
        if not buffer:
          break
        file_size_dl += len(buffer)
        f.write(buffer)
        status = r"%10d  [%3.2f%%]" % (file_size_dl, file_size_dl * 100. / file_size)
        status = status + chr(8)*(len(status)+1)
        print status,
      f.close()
      print ' Fetched file: "' + file_name + '"'
    except:
      print 'Cannot fetch file: "' + file_name + '"'

def populate_repo(repo, repo_hash):
  for item in repo_hash:
    md5sum = item['md5']
    file_name = item['name']
    mirrors = item['mirrors']
    for mirror in mirrors:
      fetch_file(repo, file_name, mirror, md5sum)
    check_file(repo, file_name, md5sum)

# Main
package_list = yaml.load(file('deployment_scripts/master/packages.yaml','r'))
for dictionary in package_list:
  for repo, repo_hash in dictionary.items():
    populate_repo(repo, repo_hash)
