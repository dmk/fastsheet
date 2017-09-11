# frozen_string_literal: true

require 'mkmf'

create_makefile 'rutgem'

makefile = %(
.ONESHELL:
all:
	cd fastsheet
	sh ./build.sh
clean:
	rm -rf ./fastsheet/target
install: ;
)

File.write('Makefile', makefile)
