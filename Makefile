default: clean build-module build-rpm

clean:
	rm -f Routing.{c,so}

build-module:
	python setup.py build_ext --inplace
build-rpm:
	python setup.py bdist --format=rpm
