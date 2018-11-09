# -*- coding:utf-8 -*-
import urllib2
import json
import threading
from time import ctime, sleep

def guest(n):
	try:
		msg = {}
		headers = {"Content-Type":"application/json"}
		request = urllib2.Request(url="http://121.46.2.131:1888/guest", headers=headers, data=json.dumps(msg))
		#request = urllib2.Request(url="http://121.46.2.131:8080/guest", headers=headers, data=json.dumps(msg))
		print("请求开始")
		response = urllib2.urlopen(request, timeout=1)
		response.read()
		print("请求结束")
	except Exception, e:
		print e
	finally:
		pass

def test_guest():
	print(ctime())
	for i in range(5000):
		guest(i)
		sleep(1)
	print(ctime())

def main():
	threads = []
	for i in range(10):
		t = threading.Thread(target=test_guest)
		t.setDaemon(True)
		t.start()
		threads.append(t)
		
	for t in threads:
		t.join()
	
if __name__ == '__main__':
	main()
	