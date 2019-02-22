test:
	mkdir -p generated
	rflx generate generated specs/*.rflx
	gprbuild -Ptest
	build/test
	gnatprove -Ptest --checks-as-errors

clean:
	gprclean -Ptest
	rmdir build
